From Stdlib Require Import String List Bool.
From MetaRocq.Utils Require Import ResultMonad.
From MetaRocqRs.OriginalSelfHost Require Import
  PCUICCertificateIR HOL4KernelContract SourceLambdaBoxRefinement
  IntegratedPeregrineCakeML HOL4MachineRefinement HOL4ProofLedger
  HOL4CertificateReplayIR HOL4RecursiveSelfIdentity.

Import ListNotations.
Open Scope string_scope.

Record hol4_self_evidence := {
  hol4_self_certificate_evidence : list hol4_certificate_evidence;
  hol4_self_recursive_identity : hol4_recursive_identity
}.

Definition accept_hol4_self_evidence (e : hol4_self_evidence) : bool :=
  accept_original_hol4_certificate_corpus e.(hol4_self_certificate_evidence)
  && accept_hol4_recursive_identity e.(hol4_self_recursive_identity).

Inductive hol4_selfhost_command :=
| CompileLambdaBoxToCakeML (attrs : list string) (source : string)
| InspectHOL4KernelRequirements
| InspectHOL4CakeMLBindings
| InspectHOL4CertificateLedger
| InspectHOL4ReplayJobs
| VerifyHOL4Self (e : hol4_self_evidence).

Inductive hol4_selfhost_response :=
| HOL4CakeMLCandidate (out : candidate_cakeml_ast)
| HOL4CakeMLBlocked
| HOL4KernelRequirementsResponse (xs : list hol4_kernel_requirement)
| HOL4CakeMLBindingsResponse (xs : list cakeml_hol4_binding)
| HOL4CertificateLedgerResponse (xs : list hol4_certificate_job)
| HOL4ReplayJobsResponse (xs : list hol4_certificate_replay_job)
| HOL4SelfVerified
| HOL4SelfBlocked.

Definition hol4_kernel_requirements : list hol4_kernel_requirement :=
  [HOL4KernelBuiltFromPinnedSource;
   HOL4KernelTheoremObjectChecked;
   HOL4NoUnexpectedOracles;
   HOL4NoUnexpectedAxioms;
   HOL4StatementIdentityChecked;
   HOL4AssumptionLedgerChecked].

Definition hol4_selfhost_entrypoint
  (cmd : hol4_selfhost_command) : hol4_selfhost_response :=
  match cmd with
  | CompileLambdaBoxToCakeML attrs source =>
      match integrated_lambdabox_to_cakeml attrs source with
      | Ok out => HOL4CakeMLCandidate out
      | Err _ => HOL4CakeMLBlocked
      end
  | InspectHOL4KernelRequirements =>
      HOL4KernelRequirementsResponse hol4_kernel_requirements
  | InspectHOL4CakeMLBindings =>
      HOL4CakeMLBindingsResponse cakeml_hol4_bindings
  | InspectHOL4CertificateLedger =>
      HOL4CertificateLedgerResponse original_hol4_certificate_ledger
  | InspectHOL4ReplayJobs =>
      HOL4ReplayJobsResponse original_hol4_replay_jobs
  | VerifyHOL4Self e =>
      if accept_hol4_self_evidence e
      then HOL4SelfVerified
      else HOL4SelfBlocked
  end.

Definition retained_hol4_certificate_corpus : list pcuic_theorem_certificate :=
  original_pcuic_certificate_corpus.

Definition retained_hol4_certificate_jobs : list hol4_certificate_job :=
  original_hol4_certificate_ledger.

Definition retained_hol4_replay_jobs : list hol4_certificate_replay_job :=
  original_hol4_replay_jobs.

Theorem unresolved_hol4_identity_blocks_self_verification :
  forall certs,
    accept_hol4_self_evidence
      {| hol4_self_certificate_evidence := certs;
         hol4_self_recursive_identity := unresolved_hol4_recursive_identity |}
    = false.
Proof.
  intros.
  unfold accept_hol4_self_evidence.
  destruct (accept_original_hol4_certificate_corpus certs); reflexivity.
Qed.
