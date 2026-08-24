# Bellman

`Contraction.lean` lifts the exact rational data in
`Value/FiniteHorizon.lean` to real-valued tables on the finite
belief--compressed-state product. It proves the continue and research action
operators are Lipschitz with modulus at most the rational discount, proves the
finite-action maximum Bellman operator is a contraction in the sup norm, and
applies mathlib's Banach fixed-point theorem.

The resulting unique fixed point has uniform value-iteration convergence and
the standard geometric a priori error bound. The exact rational finite-horizon
recursion is proved to cast to the real recursion, hence converges pointwise to
the fixed point. Cost-sensitive dynamic innovation equivalent compressed
states have equal fixed-point values.

This is a supporting extension of the primitive compressed-state process. It
does not construct the accepted raw-library Bellman model, prove a raw versus
compressed simulation, or construct a stationary policy object.
