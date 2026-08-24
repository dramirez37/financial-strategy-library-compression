import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Basic

/-!
# Finite model carriers

This file packages the nonempty finite carrier types used by the foundational
strategy-innovation model.  Economic data live in later files; the carrier
record supplies only finiteness, decidable equality, and nonemptiness.
-/

namespace StrategyInnovation

universe u

/--
The finite carrier types of one strategy-innovation model.

`Belief` is a finite belief-grid label, `StrategyId` and `ModuleId` index the
finite strategy and capability catalogs, and `ResearchProject` indexes the
finite project menu.
-/
structure FiniteModel where
  Belief : Type u
  StrategyId : Type u
  ModuleId : Type u
  ResearchProject : Type u
  [beliefFintype : Fintype Belief]
  [beliefDecidableEq : DecidableEq Belief]
  [beliefNonempty : Nonempty Belief]
  [strategyFintype : Fintype StrategyId]
  [strategyDecidableEq : DecidableEq StrategyId]
  [strategyNonempty : Nonempty StrategyId]
  [moduleFintype : Fintype ModuleId]
  [moduleDecidableEq : DecidableEq ModuleId]
  [moduleNonempty : Nonempty ModuleId]
  [projectFintype : Fintype ResearchProject]
  [projectDecidableEq : DecidableEq ResearchProject]
  [projectNonempty : Nonempty ResearchProject]

instance (model : FiniteModel) : Fintype model.Belief :=
  model.beliefFintype

instance (model : FiniteModel) : DecidableEq model.Belief :=
  model.beliefDecidableEq

instance (model : FiniteModel) : Nonempty model.Belief :=
  model.beliefNonempty

instance (model : FiniteModel) : Fintype model.StrategyId :=
  model.strategyFintype

instance (model : FiniteModel) : DecidableEq model.StrategyId :=
  model.strategyDecidableEq

instance (model : FiniteModel) : Nonempty model.StrategyId :=
  model.strategyNonempty

instance (model : FiniteModel) : Fintype model.ModuleId :=
  model.moduleFintype

instance (model : FiniteModel) : DecidableEq model.ModuleId :=
  model.moduleDecidableEq

instance (model : FiniteModel) : Nonempty model.ModuleId :=
  model.moduleNonempty

instance (model : FiniteModel) : Fintype model.ResearchProject :=
  model.projectFintype

instance (model : FiniteModel) : DecidableEq model.ResearchProject :=
  model.projectDecidableEq

instance (model : FiniteModel) : Nonempty model.ResearchProject :=
  model.projectNonempty

end StrategyInnovation
