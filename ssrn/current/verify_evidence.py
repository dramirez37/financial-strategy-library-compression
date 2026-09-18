#!/usr/bin/env python3
"""Read-only checks of the public evidence distributed with this paper."""
import csv, hashlib, json, math, statistics, tomllib
from collections import Counter
from fractions import Fraction
from pathlib import Path
ROOT = Path(__file__).resolve().parent

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rows(p):
    with (ROOT / 'evidence' / p).open(newline='') as f: return list(csv.DictReader(f))
def toml(p): return tomllib.loads((ROOT / 'evidence' / p).read_text())
def verify():
    manifest=json.loads((ROOT/'REPRODUCTION_MANIFEST.json').read_text())
    for path, spec in manifest['bundled_evidence'].items():
        assert sha(ROOT/path)==spec['sha256'],path
    audit=toml('benchmark/audit_summary.toml'); runs=rows('benchmark/final_algorithm_runs.csv')
    assert len(runs)==audit['expected_run_count']==3907
    assert dict(Counter(r['status'] for r in runs))==audit['status_counts']
    assert sum(r['candidate_accepted']=='true' for r in runs)==3526
    assert sum(r['analysis_included']=='true' for r in rows('benchmark/FINAL_INSTANCE_REGISTRY.csv'))==173
    exact=rows('benchmark/exact_method_agreement.csv')
    assert len(exact)==38 and sum(r['exact_agreement']=='true' for r in exact)==31
    ledger=rows('mechanism/V4_WORLD_LEDGER.csv'); summaries=rows('mechanism/V4_SUMMARY.csv')
    assert len(ledger)==16384 and len(summaries)==4
    for summary in summaries:
        group=[r for r in ledger if r['regime_id']==summary['regime_id']]
        assert len(group)==int(summary['world_count'])==4096
        for field,col in [('oracle_value','oracle_mean'),('learned_value','learned_mean')]:
            assert math.isclose(statistics.mean(float(r[field]) for r in group),float(summary[col]),abs_tol=1e-14)
        rate=sum(r['learned_adopt']=='true' for r in group)/len(group)
        assert rate==float(summary['adoption_rate'])
        assert all(r['structural_valid']=='true' for r in group)
    for filename,sealname,key in [
        ('PREDECISION_COMPUTATION_MANIFEST.toml','PREDECISION_COMPUTATION_RESULT_SEAL.toml','public_result_manifest_sha256'),
        ('PROPOSAL_POLICY_MANIFEST.toml','PROPOSAL_POLICY_RESULT_SEAL.toml','public_proposal_policy_manifest_sha256'),
        ('EVALUATION_RESULT_MANIFEST.toml','EVALUATION_RESULT_SEAL.toml','evaluation_result_manifest_sha256')]:
        assert sha(ROOT/'evidence/financial'/filename)==toml('financial/'+sealname)[key]
    pre=toml('financial/PREDECISION_COMPUTATION_MANIFEST.toml')
    assert pre['all_exact_postchecks_passed'] and not pre['return_values_included'] and not pre['licensed_security_identifiers_included']
    counts=Counter(c['universe_id'] for c in pre['cells'] if c['universe_gate_passed'])
    assert counts=={'liquid_common_equity':19,'liquid_plain_etf':18}
    proposal=toml('financial/PROPOSAL_POLICY_MANIFEST.toml')
    assert proposal['evaluation_values_used']==0 and not proposal['selected_strategy_identities_included']
    evaluation=toml('financial/EVALUATION_RESULT_MANIFEST.toml')
    assert not evaluation['return_values_included'] and not evaluation['licensed_identifiers_included']
    financial={}
    for universe,key in [('liquid_common_equity','common_equity_summary'),('liquid_plain_etf','etf_replication_summary')]:
        cells=[c for c in pre['cells'] if c['universe_id']==universe and c['universe_gate_passed']]
        source=[Fraction(c['source_exact_burden'].replace('//','/')) for c in cells]
        safe=[Fraction(c['safe_exact_burden'].replace('//','/')) for c in cells]
        summary=evaluation[key]; origin=[r for r in summary['origin_values'] if r['complete']]
        assert len(origin)==summary['complete_origin_count']==len(cells)
        assert sum(r['same_choice'] for r in origin)==summary['same_choice_count']
        assert math.isclose(statistics.mean(r['certainty_equivalent_difference'] for r in origin),summary['arithmetic_mean'],abs_tol=1e-14)
        financial[universe]={'source_burden_mean':float(statistics.mean(source)),'safe_burden_mean':float(statistics.mean(safe)),'burden_reduction_mean':float(statistics.mean(1-a/b for a,b in zip(safe,source))),'added_options_mean':statistics.mean(int(c['innovation_option_count']) for c in cells),'heldout_ce_mean':summary['arithmetic_mean'],'same_choice_count':summary['same_choice_count']}
    result={'financial_summaries':financial,'passed':True,'evidence_files':len(manifest['bundled_evidence']),'benchmark_instances':173,'terminal_runs':3907,'accepted_libraries':3526,'exact_agreement':31,'exact_denominator':38,'synthetic_worlds':16384,'financial_origins':dict(counts),'scope':'Read-only public-record verification; no scientific experiment rerun.'}
    return result
if __name__=='__main__': print(json.dumps(verify(),indent=2))
