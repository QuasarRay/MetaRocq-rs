import base64
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT), str(ROOT / 'infra')]
from pipelines.roadmap import load, states
from agentinfra.process import run_process


class RoadmapTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'input').write_text('original')
        (self.root / 'output').write_text('artifact')
        self.doc = {'schema': 1, 'id': 'test', 'policy': {'max_active_agents': 1,
            'reasoning_effort': 'max', 'formalization_model': 'gpt-6-astra', 'implementation_gate': 'proof'},
            'tasks': [{'id': 'audit', 'kind': 'bootstrap', 'depends_on': [], 'inputs': ['input'],
                       'command': ['python3', '-c', 'print(1)'],
                       'acceptance': {'kind': 'process', 'required_artifacts': ['output'], 'required_theorems': []}},
                      {'id': 'proof', 'kind': 'bootstrap', 'depends_on': ['audit'], 'inputs': [], 'command': None,
                       'acceptance': {'kind': 'proof', 'required_artifacts': ['certificate'], 'required_theorems': ['equivalence']}},
                      {'id': 'implementation', 'kind': 'implementation', 'depends_on': ['proof'], 'inputs': [], 'command': None,
                       'acceptance': {'kind': 'process', 'required_artifacts': ['source'], 'required_theorems': []}}]}

    def validate(self, doc=None):
        p = self.root / 'roadmap.json'
        p.write_text(json.dumps(doc or self.doc))
        return load(p)

    def test_actual_roadmap(self):
        doc, tasks = load(ROOT / 'roadmaps/metarocq-bootstrap.json')
        self.assertEqual(len(tasks), 12)
        self.assertEqual(doc['policy']['implementation_gate'], 'metatheory-verified')

    def test_invalid_dags_and_policy_fail_closed(self):
        mutations = [lambda d: d['tasks'][0].update(depends_on=['proof']),
                     lambda d: d['tasks'][0].update(inputs=['../outside']),
                     lambda d: d['tasks'][0].update(command='echo unsafe'),
                     lambda d: d['tasks'][2].update(depends_on=['audit']),
                     lambda d: d['tasks'][1]['acceptance'].update(kind='process', required_theorems=[]),
                     lambda d: d['policy'].update(max_active_agents=2),
                     lambda d: d['tasks'][0].update(status='verified')]
        for change in mutations:
            with self.subTest(change=change):
                doc = copy.deepcopy(self.doc)
                change(doc)
                with self.assertRaises(ValueError):
                    self.validate(doc)

    def test_forged_proof_and_stale_process_evidence(self):
        from pipelines.roadmap import identities
        doc, tasks = self.validate()
        current = states(self.root, doc, tasks, [], 'runtime')
        event = {'kind': 'task_finished', 'task': 'audit', 'identity': current['audit']['identity'],
                 'outcome': 'OBSERVED', 'outputs': identities(self.root, ['output'])}
        forged = {'kind': 'task_finished', 'task': 'proof', 'identity': current['proof']['identity'],
                  'outcome': 'OBSERVED', 'verified': True, 'outputs': {}}
        result = states(self.root, doc, tasks, [event, forged], 'runtime')
        self.assertEqual(result['audit']['status'], 'OBSERVED')
        self.assertEqual(result['proof']['status'], 'BLOCKED')
        self.assertEqual(result['implementation']['status'], 'BLOCKED')
        (self.root / 'input').write_text('changed')
        stale = states(self.root, doc, tasks, [event], 'runtime')
        self.assertEqual(stale['audit']['status'], 'READY')
        self.assertNotEqual(stale['proof']['identity'], current['proof']['identity'])

    def test_interruption_is_not_silently_retried(self):
        doc, tasks = self.validate()
        current = states(self.root, doc, tasks, [], 'runtime')
        event = {'kind': 'task_started', 'task': 'audit', 'identity': current['audit']['identity']}
        self.assertEqual(states(self.root, doc, tasks, [event], 'runtime')['audit']['status'], 'BLOCKED')

    def test_full_output_reaches_sink_despite_bounded_display(self):
        chunks = []
        result = run_process([sys.executable, '-c', "import sys;sys.stdout.write('x'*150000)"],
                             cwd=self.root, capture_limit=1024, event_sink=lambda stream, data: chunks.append((stream, data)))
        self.assertTrue(result.stdout_truncated)
        self.assertEqual(b''.join(data for stream, data in chunks if stream == 'stdout'), b'x' * 150000)

    def test_capture_failure_aborts_process(self):
        def fail(stream, chunk):
            raise OSError('database unavailable')
        with self.assertRaisesRegex(RuntimeError, 'durable event capture failed'):
            run_process([sys.executable, '-c', "print('event')"], cwd=self.root, event_sink=fail)
