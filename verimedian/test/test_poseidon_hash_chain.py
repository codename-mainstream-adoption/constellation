# (c) Justin Beaurone
import time
import numpy as np
from verimedian import poseidon_hash_chain


x = np.array([int(i) for i in range(1000)], dtype=object)

def test_poseidon_hash_chain():
    assert poseidon_hash_chain(x) > int(0)