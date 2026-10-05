#!/usr/bin/env python3
"""Read actual compiler proof objects through the pinned .agents MCP adapter.

MCP remains an orchestration aid. The direct Holmake builds and their closed
theorem objects are the proof boundary; this report cannot replace them.
"""
import argparse
import asyncio
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.agents/infra'))
from agentinfra.hol4 import mcp_stdio_config, validate_mcp_probe
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

COMMAND = '''load "OriginalCompilerOutputAutomationContractTheory";
load "OriginalCompilerOutputTacticToeTheory";
open OriginalBootstrapCompilerProbeTheory
     OriginalCompilerOutputAutomationContractTheory
     OriginalCompilerOutputTacticToeTheory;
val _ = ((let
  val inspected = [original_bootstrap_probe_compiled,
    library_code_length,library_data_length,
    library_code_address_bounds_z3,library_code_data_offsets_disjoint_z3,
    probe_code_nonempty_tactictoe]
  fun inspect th = let val (oracles,axioms) = Tag.dest_tag (Thm.tag th) in
    if null (Thm.hyp th) andalso null axioms andalso
       List.all (fn name => name = "DISK_THM") oracles
    then print (term_to_string (concl th) ^ "\\n")
    else raise Fail "Open or contaminated loaded theorem" end
in List.app inspect inspected;
   print "ORIGINAL_COMPILER_MCP_INSPECTION_COMPLETE\\n"
end) handle e => print ("ORIGINAL_COMPILER_MCP_INSPECTION_FAILED: " ^ General.exnMessage e ^ "\\n"));
'''


async def inspect(args):
    config = mcp_stdio_config(ROOT)
    packet = {'claim': 'MCP read-only observation; direct Holmake is the proof boundary',
              'configuration': config, 'calls': [], 'status': 'FAILED'}
    params = StdioServerParameters(command=config['command'], args=config['args'],
                                   env={**os.environ, **config['env']})
    try:
        async with asyncio.timeout(args.timeout):
            async with stdio_client(params) as streams:
                async with ClientSession(*streams) as session:
                    await session.initialize()
                    async def call(tool, arguments):
                        result = await session.call_tool(tool, arguments)
                        payload = result.model_dump(by_alias=True)
                        packet['calls'].append({'tool': tool, 'arguments': arguments, 'result': payload})
                        validate_mcp_probe(result)
                        return '\n'.join(c.get('text', '') for c in payload.get('content', []))
                    name = 'original-compiler-inspection'
                    await call('hol_start', {'workdir': str(ROOT / 'formal/hol4/compiler-automation'),
                                            'name': name, 'env': {'CAKEMLDIR': str(args.cakemldir.resolve(strict=True))}})
                    try:
                        response = await call('hol_send', {'session': name, 'timeout': args.timeout - 10,
                                                          'max_output': 15000, 'command': COMMAND})
                        if ('ORIGINAL_COMPILER_MCP_INSPECTION_COMPLETE' not in response or
                            any(text in response for text in ('INSPECTION_FAILED:', 'Exception-', 'error:'))):
                            raise RuntimeError('HOL query did not complete successfully')
                        packet['status'] = 'ORCHESTRATION_READY'
                    finally:
                        await call('hol_stop', {'session': name})
    except Exception as error:
        packet['status'] = 'FAILED'
        packet['error'] = str(error)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(packet, indent=2) + '\n')
    print(json.dumps({'status': packet['status'], 'report': str(args.output), 'claim': packet['claim']}))
    return 0 if packet['status'] == 'ORCHESTRATION_READY' else 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cakemldir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--timeout', type=int, default=90)
    args = parser.parse_args()
    if args.timeout <= 10:
        parser.error('timeout must exceed 10 seconds')
    raise SystemExit(asyncio.run(inspect(args)))
