#include <metal_stdlib>
#include <metal_math>
#
using namespace metal;

METAL_FUNC uint get_strided_index(
    uint idx,
    constant size_t &num_dims,
    constant size_t *dims,
    constant size_t *strides
) {
    uint strided_i = 0;
    for (uint d = 0; d < num_dims; d++) {
        uint dim_idx = num_dims - 1 - d;
        strided_i += (idx % dims[dim_idx]) * strides[dim_idx];
        idx /= dims[dim_idx];
    }
    return strided_i;
}

template <typename T> METAL_FUNC T sqr(T in){ return in * in; }
template <typename T> METAL_FUNC T neg(T in){ return -in; }
template <typename T> METAL_FUNC T id(T in){ return in; }
template <typename T> METAL_FUNC T gelu(T x){
    T x_sq = x * x;
    T x_cube = x_sq * x;
    T alpha = x + static_cast<T>(0.044715) * x_cube;
    T beta =  (static_cast<T>(M_2_SQRTPI_F * M_SQRT1_2_F) * alpha);
    return static_cast<T>(0.5) * x * (static_cast<T>(1.0) + tanh(beta));
}



#define UNARY(FN, TYPENAME, FN_NAME, FN_NAME_STRIDED) \
kernel void FN_NAME( \
    constant size_t &dim, \
    device const TYPENAME *input,  \
    device TYPENAME *output, \
    uint thread_position_in_grid [[ thread_position_in_grid ]] \
) { \
    if (thread_position_in_grid >= dim) { \
        return; \
    } \
    output[thread_position_in_grid] = TYPENAME(FN(input[thread_position_in_grid])); \
}\
kernel void FN_NAME_STRIDED( \
    constant size_t &dim, \
    constant size_t &num_dims, \
    constant size_t *dims, \
    constant size_t *strides, \
    device const TYPENAME *input,  \
    device TYPENAME *output, \
    uint thread_position_in_grid [[ thread_position_in_grid ]] \
) { \
    if (thread_position_in_grid >= dim) { \
        return; \
    } \
    output[thread_position_in_grid] = TYPENAME(FN(input[get_strided_index(thread_position_in_grid, num_dims, dims, strides)])); \
}

#define UNARY_OP(NAME) \
UNARY(NAME, float, NAME##_float, NAME##_float_strided); \
UNARY(NAME, half, NAME##_half, NAME##_half_strided);

#define BFLOAT_UNARY_OP(NAME) \
UNARY(NAME, bfloat, NAME##_bfloat, NAME##_bfloat_strided);


UNARY_OP(cos)
UNARY_OP(sin)
UNARY_OP(sqr)
UNARY_OP(sqrt)
UNARY_OP(neg)
UNARY_OP(exp)
UNARY_OP(log)
UNARY_OP(gelu)
UNARY_OP(ceil)
UNARY_OP(floor)
UNARY_OP(round)
UNARY(id, float, copy_float, copy_float_strided)
UNARY(id, half, copy_half, copy_half_strided)
UNARY(id, uint8_t, copy_u8, copy_u8_strided)
UNARY(id, uint32_t, copy_u32, copy_u32_strided)

#if __METAL_VERSION__ >= 310
BFLOAT_UNARY_OP(cos)
BFLOAT_UNARY_OP(sin)
BFLOAT_UNARY_OP(sqr)
BFLOAT_UNARY_OP(sqrt)
BFLOAT_UNARY_OP(neg)
BFLOAT_UNARY_OP(exp)
BFLOAT_UNARY_OP(log)
BFLOAT_UNARY_OP(gelu)
BFLOAT_UNARY_OP(ceil)
BFLOAT_UNARY_OP(floor)
BFLOAT_UNARY_OP(round)

UNARY(id, bfloat, copy_bfloat, copy_bfloat_strided)
#endif
