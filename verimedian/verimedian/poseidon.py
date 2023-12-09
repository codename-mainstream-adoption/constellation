# (c) Justin Beaurone
from . import np
from . import load_poseidon_constants
from . import check_type_array
from . import P


N_ROUNDS_F = 8
N_ROUNDS_P = [56, 57, 56, 60, 60, 63, 64, 63, 60, 66, 60, 65, 70, 60, 64, 68]
OPTIMIZED_CONSTANTS = load_poseidon_constants()
ZERO = int(0)

def add(x: int, y: int) -> int:
    # addition modulo P
    return (x + y) % P

def mul(x: int, y: int) -> int:
    # multiplication modulo P
    return (x * y) % P

def square(x: int) -> int:
    # exponentiation by squaring modulo P
    return mul(x, x)

def pow5(x: int) -> int:
    # exponentiation by squaring modulo P
    return mul(x, square(square(x)))

def normalize(x: int) -> int:
    # normalize positive or negative integers modulo P
    return x % P if x >= 0 else P - ((-1 * x) % P)

def poseidon_hash(inputs: np.ndarray) -> int:
    """Perform the poseidon hash on the inputs array. Inputs must be an array
    between 1 and 16 in length, and it must be only Python integers.

    inputs:
    inputs - array of integers to hash

    outputs:
    h      - hash of the inputs array
    """
    if (ti := type(inputs)) != np.ndarray:
        raise ValueError(f"Type of `inputs`: ({ti}) is invalid. " \
                         + "Expected type of np.ndarray.")
    if (td := inputs.dtype) != object:
        raise ValueError(f"Type of `inputs.dtype`: ({td}) is invalid. " \
                         + "Expected type of 'object'.")
    if not np.all(check_type_array(inputs) == int):
        raise ValueError(f"Type of elements `inputs`: ({td}) is invalid. " \
                         + "Expected all elements to be of type `int`.")
    if (s := inputs.size) < 1 or s > 16:
        raise ValueError(f"Length of inputs: ({s}) is invalid. " \
                         + "Expected 1 <= s <= 16.")

    t = inputs.size + 1
    n_rounds_f = N_ROUNDS_F
    n_rounds_p = N_ROUNDS_P[t - 2]
    C = OPTIMIZED_CONSTANTS["C"][t - 2]
    S = OPTIMIZED_CONSTANTS["S"][t - 2]
    M = OPTIMIZED_CONSTANTS["M"][t - 2]
    P = OPTIMIZED_CONSTANTS["P"][t - 2]

    state = np.array([ZERO, *inputs], dtype=object)
    state_temp = np.zeros_like(state)
    I = np.arange(state.size, dtype=int)

    state = add(state, C[I])
    for r in range(int(n_rounds_f / 2) - 1):
        state = pow5(state)
        state = add(state, C[(r + 1) * t + I])
        for i in range(state.size):
            accumulator = ZERO
            for j in range(state.size):
                accumulator = add(accumulator, mul(M[j][i], state[j]))
            state_temp[i] = accumulator
        state = state_temp

    state = pow5(state)
    state = add(state, C[int(n_rounds_f / 2) * t + I])

    for i in range(state.size):
        accumulator = ZERO
        for j in range(state.size):
            accumulator = add(accumulator, mul(P[j][i], state[j]))
        state_temp[i] = accumulator
    state = state_temp

    for r in range(n_rounds_p):
        state[0] = add(pow5(state[0]), C[int(n_rounds_f / 2 + 1) * t + r])
        s0 = ZERO
        for i in range(state.size):
            s0 = add(s0, mul(S[int((t * 2 - 1) * r) + i], state[i]))
        for k in range(1, t):
            state[k] = add(state[k], mul(
                state[0], S[int((t*2 - 1) * r) + t + k - 1]
            ))
        state[0] = s0

    for r in range(int(n_rounds_f / 2) - 1):
        state = pow5(state)
        state = add(state, C[int((n_rounds_f / 2 + 1) * t) \
                             + n_rounds_p + int(r * t) + I])
        for i in range(state.size):
            accumulator = ZERO
            for j in range(state.size):
                accumulator = add(accumulator, mul(M[j][i], state[j]))
            state_temp[i] = accumulator
        state = state_temp

    state = pow5(state)

    for i in range(state.size):
        accumulator = ZERO
        for j in range(state.size):
            accumulator = add(accumulator, mul(M[j][i], state[j]))
        state_temp[i] = accumulator

    state = state_temp

    return normalize(state[0])

def poseidon_hash_chain(x: np.ndarray, initial_hash: int = int(0)) -> int:
    '''Hashes a list of values in pairs by the pattern:
    h_0 = poseidon_hash([0, x[0]])
    h_1 = poseidon_hash([h_0, x[1]])
    ...
    h_n  = poseidon_hash([h_n-1, x[n]])

    inputs:
    x - list of values to hash

    outputs:
    h - hash of the list of values
    '''
    hash_chain_value = initial_hash
    for i in range(x.size):
        inputs = np.array([hash_chain_value, x[i]], dtype=object)
        hash_chain_value = poseidon_hash(inputs)
    return hash_chain_value