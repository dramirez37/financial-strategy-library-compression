#!/usr/bin/env python3
"""Small independent checks supporting the manuscript review, not universal proofs."""
import json, math
from fractions import Fraction as F
from build_figures import build as check_figures

def verify():
    # An optional project can be declined; its cap need not be attained.
    discount,success,cap,cost=F(1,2),F(1,2),F(4),F(1,2)
    values=[max(F(0),discount*success*gain-cost) for gain in [F(0),F(1),F(2),F(4)]]
    assert values==[0,0,0,F(1,2)]
    assert all(v<=discount*success*cap-cost for v in values)
    # Exact oracle-law counterexample to reflection-invariant one-sided coverage.
    reflected=1+math.log(.9); conventional=-math.log(.1)-1
    reflected_coverage=1-math.exp(-(reflected+1))
    conventional_coverage=1-math.exp(-(conventional+1))
    assert math.isclose(reflected_coverage,1-math.exp(-2)/.9,abs_tol=1e-15)
    assert reflected_coverage<.9 and math.isclose(conventional_coverage,.9,abs_tol=1e-15)
    # Unit-weight fixed no-instance used in the NP-completeness normalization.
    candidates=[(set(),0),({"u"},1)]
    assert not any(cover=={"u"} and burden<=0 for cover,burden in candidates)
    # A path/outcome law can remember an earlier state after current states merge.
    # Two equally likely paths share b_2 and time-to-completion but imply different outcomes.
    paths=[((0,1,3,4),0,F(1,2)),((0,2,3,4),1,F(1,2))]
    assert sum(p for _,_,p in paths)==1
    assert paths[0][0][2]==paths[1][0][2] and paths[0][1]!=paths[1][1]
    return {'passed':True,'figure_checks':check_figures(check=True),
      'optional_bridge_fixture':{'gains':['0','1','2','4'],'optimal_losses':list(map(str,values)),'sharp_cap_bound':'1/2'},
      'reflected_error_counterexample':{'law':'E=Exp(1)-1, known unit standard deviation','nominal_level':.9,'reflected_critical':reflected,'reflected_coverage':reflected_coverage,'upper_error_critical':conventional,'upper_error_coverage':conventional_coverage,'scope':'Analytic counterexample only; not estimated coverage for the financial study.'},
      'unit_weight_no_instance_checked':True,'within_project_history_counterexample_checked':True,
      'scope':'Independent small checks and full public-ledger figure reconciliation; no new financial result or universal proof.'}
if __name__=='__main__':print(json.dumps(verify(),indent=2))
