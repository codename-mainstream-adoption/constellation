# (c) Justin Beaurone
import numpy as np
from verimedian import poseidon_hash


poseidon1_ref = int(
    '0x2a09a9fd93c590c26b91effbb2499f07e8f7aa12e2b4940a3aed2411cb65e11c', 16)
poseidon3_ref = int(
    "0x115cc0f5e7d690413df64c6b9662e9cf2a3617f2743245519e19607a4417189a", 16)
poseidon5_ref = int(
    "0x299c867db6c1fdd79dcefa40e4510b9837e60ebb1ce0663dbaa525df65250465", 16)

def test_poseidon1():
    poseidon1_input = np.array([0], dtype=object)
    assert poseidon1_ref == poseidon_hash(poseidon1_input)

def test_poseidon3():
    poseidon3_input = np.array([1, 2], dtype=object)
    assert poseidon3_ref == poseidon_hash(poseidon3_input)

def test_poseidon5():
    poseidon5_input = np.array([1, 2, 3, 4], dtype=object)
    assert poseidon5_ref == poseidon_hash(poseidon5_input)