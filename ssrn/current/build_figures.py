#!/usr/bin/env python3
"""Deterministic PGFPlots inputs from the sealed public evidence (no simulation)."""
import argparse, csv, hashlib, io, json, math, statistics, tomllib
from pathlib import Path
from verify_evidence import verify
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'article'/'figures'
def csv_text(fields, rows):
    stream=io.StringIO(newline=''); writer=csv.DictWriter(stream,fieldnames=fields,lineterminator='\n')
    writer.writeheader(); writer.writerows(rows); return stream.getvalue()
def make_inputs():
    evidence=verify()
    def toml(name):return tomllib.loads((ROOT/'evidence'/name).read_text())
    ev=toml('financial/EVALUATION_RESULT_MANIFEST.toml')
    financial=[]; origins=[]
    for index,(universe,key) in enumerate([('liquid_common_equity','common_equity_summary'),('liquid_plain_etf','etf_replication_summary')]):
        summary=evidence['financial_summaries'][universe]
        financial.append(dict(group=index,burden_reduction_pct=100*summary['burden_reduction_mean'],added_options=summary['added_options_mean'],complete_origins=evidence['financial_origins'][universe]))
        for row in ev[key]['origin_values']:
            origins.append(dict(group=index,origin=int(row['origin_id'].split('O')[-1]),complete=int(row['complete']),ce_pp=100*row['certainty_equivalent_difference'] if row['complete'] else 'nan',same_choice=int(row['same_choice'])))
    with (ROOT/'evidence/mechanism/V4_SUMMARY.csv').open() as f:summary=list(csv.DictReader(f))
    mechanism=[]
    for i,row in enumerate(summary):
        record={'regime':i,'true_margin':float(row['true_margin'])}
        for who in ['oracle','learned']:
            mean=float(row[who+'_mean']);record[who]=mean
            record[who+'_minus']=mean-float(row[who+'_ci_lower']);record[who+'_plus']=float(row[who+'_ci_upper'])-mean
        rate=float(row['adoption_rate']);record['adoption_pct']=100*rate
        record['adoption_minus']=100*(rate-float(row['adoption_wilson_lower']));record['adoption_plus']=100*(float(row['adoption_wilson_upper'])-rate)
        mechanism.append(record)
    # Recompute uncertainty independently from individual synthetic worlds.
    with (ROOT/'evidence/mechanism/V4_WORLD_LEDGER.csv').open() as f:ledger=list(csv.DictReader(f))
    for row in summary:
        group=[x for x in ledger if x['regime_id']==row['regime_id']];n=len(group)
        for who in ['oracle','learned']:
            values=[float(x[who+'_value']) for x in group];se=statistics.stdev(values)/math.sqrt(n);mean=statistics.mean(values)
            for column,value in [('standard_error',se),('ci_lower',mean-1.96*se),('ci_upper',mean+1.96*se)]:
                assert math.isclose(float(row[who+'_'+column]),value,abs_tol=1e-14), (row['regime_id'],column)
        p=sum(x['learned_adopt']=='true' for x in group)/n;z=1.96
        center=(p+z*z/(2*n))/(1+z*z/n);half=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/(1+z*z/n)
        assert math.isclose(float(row['adoption_wilson_lower']),center-half,abs_tol=1e-14)
        assert math.isclose(float(row['adoption_wilson_upper']),center+half,abs_tol=1e-14)
    outputs={'financial_summary.csv':csv_text(financial[0].keys(),financial),
             'financial_origins.csv':csv_text(origins[0].keys(),origins),
             'mechanism_summary.csv':csv_text(mechanism[0].keys(),mechanism)}
    provenance={'scope':'Deterministic figure inputs; no new market or synthetic experiment.',
      'figure_1':{'type':'exact schematic','belief_count':1,'profiles':{'cash':0,'A':1,'B':0,'C':1},'modules':{'cash':[],'A':[],'B':['m'],'C':[]},'weights':{'cash':0,'A':1,'B':1,'C':1},'source':['cash','A','B','C'],'safe':['cash','A','B'],'frontier_only_budget_matched':['cash','A','C'],'project_requirement':['m']},
      'figure_2':{'burden':'mean of per-origin fractional reductions times 100','options':'mean additional proposal actions relative to the budget-matched frontier-only library','heldout':'safe minus frontier-only annual certainty-equivalent difference times 100 (percentage points)','missing':'2005 ETF universe gate failure remains nan, never zero','uncertainty':'origin-level descriptive outcomes; no cross-origin confidence interval'},
      'figure_3':{'value_units':'model continuation-value units, not market-return estimates','mean_intervals':'mean +/- 1.96 sample standard errors across 4096 worlds per regime','adoption_intervals':'95% Wilson using z=1.96','pairing':'common random numbers across regimes; no independent-regime inference','zoom':'separate explicitly labeled low-value scale, first three regimes'},
      'checks':{'all_synthetic_intervals_recomputed':True,'all_four_regimes_retained':True,'financial_failed_gate_retained':True},
      'source_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'evidence/financial/PREDECISION_COMPUTATION_MANIFEST.toml',ROOT/'evidence/financial/EVALUATION_RESULT_MANIFEST.toml',ROOT/'evidence/mechanism/V4_SUMMARY.csv',ROOT/'evidence/mechanism/V4_WORLD_LEDGER.csv']}}
    fixture=provenance['figure_1']
    def frontier(lib):return max(fixture['profiles'][s] for s in lib)
    def closure(lib):return set().union(*(fixture['modules'][s] for s in lib))
    source,safe,fo=[fixture[k] for k in ['source','safe','frontier_only_budget_matched']]
    assert frontier(source)==frontier(safe)==frontier(fo)==1
    assert closure(source)==closure(safe)=={'m'} and closure(fo)==set()
    assert sum(fixture['weights'][s] for s in safe)==sum(fixture['weights'][s] for s in fo)==2
    outputs['FIGURE_DATA_AUDIT.json']=json.dumps(provenance,indent=2)+'\n'
    return outputs

def build(check=False):
    outputs=make_inputs()
    for name,content in outputs.items():
        path=OUT/name
        if check:assert path.read_text()==content, 'Figure data drift: '+str(path)
        else:path.write_text(content)
    return {'passed':True,'figures':3,'source_files':4,'uncertainty_recomputed':True,'generated_files':list(outputs)}
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    print(json.dumps(build(args.check),indent=2))
