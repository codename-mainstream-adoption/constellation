"""Endpoint logic for the full_prove operation"""
import json
import numpy as np
from verimedian import P
from verimedian import verifiable_median
from verimedian import full_prove as _full_prove
from verimedian import prepare_inputs
from verimedian import unpack_proof_data


def full_prove(values, initial_hash,
               prefix='',
               proofs_fpath='proofs/',
               input_fname='input.json',
               witness_fname='witness.wtns',
               proof_fname='proof.json',
               public_fname='public.json',
               zkey_fpathname='/build/moving_median.zkey',
               verbose=False,
               ):
    """Compute the median, calculate witness, then compute zk proof.
    """
    values = np.array(values, dtype=object)
    if np.any(values > P):
        return { "message": f"some value exceeds {P}"}, 400

    if initial_hash > P:
        return { "msg": f"initialHash: ({initial_hash}) exceeds {P}"}, 400

    try:
        sorting_key, _, median = verifiable_median(values)
    except:
        return { "msg": "could not compute verifiable median" }, 500

    try:
        input_json = prepare_inputs(sorting_key, values, median, initial_hash)
    except:
        return { "msg": "could not prepare input data for prover" }, 500

    try:
        _full_prove(input_json,
                    prefix=prefix,
                    proofs_fpath=proofs_fpath,
                    input_fname=input_fname,
                    witness_fname=witness_fname,
                    proof_fname=proof_fname,
                    public_fname=public_fname,
                    zkey_fpathname=zkey_fpathname,
                    verbose=verbose
                    )
    except Exception as e:
        print(e)
        return { "msg": "could not compute zero knowledge proof", "errormsg": f"{e}" }, 500

    try:
        proof_fpath = proofs_fpath + prefix + proof_fname
        public_fpath = proofs_fpath + prefix + public_fname
        with open(proof_fpath, 'r') as f:
            proof_data = json.load(f)
        with open(public_fpath, 'r') as f:
            public_inputs = json.load(f)
    except:
        return { "msg": "could not read finished proof data" }, 500

    return { "proofData": unpack_proof_data(proof_data),
             "publicInputs": public_inputs}, 200

"""for testing in swagger-ui
{
  "values": [13, 31, 71, 63, 51,  3, 61, 11, 32,  6, 47,  1, 45, 10, 67, 26, 55,
       60,  7, 21, 33, 56, 65, 53, 18, 17, 74, 37,  2, 27,  0, 29, 52, 73,
       76, 35, 28, 48, 46, 14, 64,  9, 44, 39, 54, 68, 25, 69, 12, 40, 23,
        4, 59, 15, 38, 58, 57, 50, 16, 36, 41, 22, 75, 42, 24, 62, 70, 49,
        8, 66, 34, 30, 72, 43, 20,  5, 19],
  "initialHash": 0
}
"""