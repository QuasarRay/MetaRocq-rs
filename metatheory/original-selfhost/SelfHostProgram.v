From MetaRocqRs.OriginalSelfHost Require Import
  MaterializeSnapshot PCUICToHOL SelfHostRunner.

Module SelfHostProgram.

Definition selfhost_main
  (backend : SelfHostRunner.candle_backend)
  : SelfHostRunner.selfhost_result :=
  SelfHostRunner.run
    backend
    (PCUICToHOL.lower_complete_metatheory
       original_pcuic_metatheory_snapshot).

End SelfHostProgram.
