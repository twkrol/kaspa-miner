// Catering for different flavors
#if __OPENCL_VERSION__ <= CL_VERSION_1_1
#define STATIC
#else
#define STATIC static
#endif

/* TYPES */

typedef uchar uint8_t;
typedef char int8_t;
typedef ushort uint16_t;
typedef short int16_t;
typedef uint uint32_t;
typedef int int32_t;
typedef ulong uint64_t;
typedef long int64_t;

/* TINY KECCAK */
/** libkeccak-tiny
 *
 * A single-file implementation of SHA-3 and SHAKE.
 *
 * Implementor: David Leon Gil
 * License: CC0, attribution kindly requested. Blame taken too,
 * but not liability.
 */

/******** The Keccak-f[1600] permutation ********/

/*** Constants. ***/
constant STATIC const uint8_t rho[24] = \
  { 1,  3,   6, 10, 15, 21,
    28, 36, 45, 55,  2, 14,
    27, 41, 56,  8, 25, 43,
    62, 18, 39, 61, 20, 44};
constant STATIC const uint8_t pi[24] = \
  {10,  7, 11, 17, 18, 3,
    5, 16,  8, 21, 24, 4,
   15, 23, 19, 13, 12, 2,
   20, 14, 22,  9, 6,  1};

constant STATIC const uint64_t RC[24] = \
  {1UL, 0x8082UL, 0x800000000000808aUL, 0x8000000080008000UL,
   0x808bUL, 0x80000001UL, 0x8000000080008081UL, 0x8000000000008009UL,
   0x8aUL, 0x88UL, 0x80008009UL, 0x8000000aUL,
   0x8000808bUL, 0x800000000000008bUL, 0x8000000000008089UL, 0x8000000000008003UL,
   0x8000000000008002UL, 0x8000000000000080UL, 0x800aUL, 0x800000008000000aUL,
   0x8000000080008081UL, 0x8000000000008080UL, 0x80000001UL, 0x8000000080008008UL};


/*** Helper macros to unroll the permutation. ***/
#define rol(x, s) (((x) << s) | ((x) >> (64 - s)))
#define REPEAT6(e) e e e e e e
#define REPEAT24(e) REPEAT6(e e e e)
#define REPEAT5(e) e e e e e
#define FOR5(v, s, e) \
  v = 0;            \
  REPEAT5(e; v += s;)

/*** Keccak-f[1600] ***/
STATIC inline void keccakf(void* state) {
  uint64_t* a = (uint64_t*)state;
  uint64_t b[5] = {0};
  uint64_t t = 0;
  uint8_t x, y;

  //#pragma unroll
  for (int i = 0; i < 24; i++) {
    // Theta
    FOR5(x, 1,
         b[x] = 0;
         FOR5(y, 5,
              b[x] ^= a[x + y]; ))
    FOR5(x, 1,
         FOR5(y, 5,
              a[y + x] ^= b[(x + 4) % 5] ^ rol(b[(x + 1) % 5], 1); ))
    // Rho and pi
    t = a[1];
    x = 0;
    REPEAT24(b[0] = a[pi[x]];
             a[pi[x]] = rol(t, rho[x]);
             t = b[0];
             x++; )
    // Chi
    FOR5(y,
       5,
       FOR5(x, 1,
            b[x] = a[y + x];)
       FOR5(x, 1,
            a[y + x] = b[x] ^ ((~b[(x + 1) % 5]) & b[(x + 2) % 5]); ))
    // Iota
    a[0] ^= RC[i];
  }
}

/******** The FIPS202-defined functions. ********/

/*** Some helper macros. ***/


#define P keccakf
#define Plen 200

/** The sponge-based hash construction. **/
STATIC inline int hash(const int variant , uint8_t* out,
                       const uint8_t* in) {
  private uint8_t sizes[2] = {10, 4};
  private uint8_t a[2][Plen] = {
    { 0x3d, 0xd8, 0xf6, 0xa1, 0x0d, 0xff, 0x3c, 0x11, 0x3c, 0x7e, 0x02, 0xb7, 0x55, 0x88, 0xbf, 0x29, 0xd2, 0x44, 0xfb, 0x0e, 0x72, 0x2e, 0x5f, 0x1e, 0xa0, 0x69, 0x98, 0xf5, 0xa3, 0xa4, 0xa5, 0x1b, 0x65, 0x2d, 0x5e, 0x87, 0xca, 0xaf, 0x2f, 0x7b, 0x46, 0xe2, 0xdc, 0x29, 0xd6, 0x61, 0xef, 0x4a, 0x10, 0x5b, 0x41, 0xad, 0x1e, 0x98, 0x3a, 0x18, 0x9c, 0xc2, 0x9b, 0x78, 0x0c, 0xf6, 0x6b, 0x77, 0x40, 0x31, 0x66, 0x88, 0x33, 0xf1, 0xeb, 0xf8, 0xf0, 0x5f, 0x28, 0x43, 0x3c, 0x1c, 0x65, 0x2e, 0x0a, 0x4a, 0xf1, 0x40, 0x05, 0x07, 0x96, 0x0f, 0x52, 0x91, 0x29, 0x5b, 0x87, 0x67, 0xe3, 0x44, 0x15, 0x37, 0xb1, 0x25, 0xa4, 0xf1, 0x70, 0xec, 0x89, 0xda, 0xe9, 0x82, 0x8f, 0x5d, 0xc8, 0xe6, 0x23, 0xb2, 0xb4, 0x85, 0x1f, 0x60, 0x1a, 0xb2, 0x46, 0x6a, 0xa3, 0x64, 0x90, 0x54, 0x85, 0x34, 0x1a, 0x85, 0x2f, 0x7a, 0x1c, 0xdd, 0x06, 0x0f, 0x42, 0xb1, 0x3b, 0x56, 0x1d, 0x02, 0xa2, 0xc1, 0xe4, 0x68, 0x16, 0x45, 0xe4, 0xe5, 0x1d, 0xba, 0x8d, 0x5f, 0x09, 0x05, 0x41, 0x57, 0x02, 0xd1, 0x4a, 0xcf, 0xce, 0x9b, 0x84, 0x4e, 0xca, 0x89, 0xdb, 0x2e, 0x74, 0xa8, 0x27, 0x94, 0xb0, 0x48, 0x72, 0x52, 0x8b, 0xe7, 0x9c, 0xce, 0xfc, 0xb1, 0xbc, 0xa5, 0xaf, 0x82, 0xcf, 0x29, 0x11, 0x5d, 0x83, 0x43, 0x82, 0x6f, 0x78, 0x7c, 0xb9, 0x02 },
    { 0x09, 0x85, 0x24, 0xb2, 0x52, 0x4c, 0xd7, 0x3a, 0x16, 0x42, 0x9f, 0x2f, 0x0e, 0x9b, 0x62, 0x79, 0xee, 0xf8, 0xc7, 0x16, 0x48, 0xff, 0x14, 0x7a, 0x98, 0x64, 0x05, 0x80, 0x4c, 0x5f, 0xa7, 0x11, 0xda, 0xce, 0xee, 0x44, 0xdf, 0xe0, 0x20, 0xe7, 0x69, 0x40, 0xf3, 0x14, 0x2e, 0xd8, 0xc7, 0x72, 0xba, 0x35, 0x89, 0x93, 0x2a, 0xff, 0x00, 0xc1, 0x62, 0xc4, 0x0f, 0x25, 0x40, 0x90, 0x21, 0x5e, 0x48, 0x6a, 0xcf, 0x0d, 0xa6, 0xf9, 0x39, 0x80, 0x0c, 0x3d, 0x2a, 0x79, 0x9f, 0xaa, 0xbc, 0xa0, 0x26, 0xa2, 0xa9, 0xd0, 0x5d, 0xc0, 0x31, 0xf4, 0x3f, 0x8c, 0xc1, 0x54, 0xc3, 0x4c, 0x1f, 0xd3, 0x3d, 0xcc, 0x69, 0xa7, 0x01, 0x7d, 0x6b, 0x6c, 0xe4, 0x93, 0x24, 0x56, 0xd3, 0x5b, 0xc6, 0x2e, 0x44, 0xb0, 0xcd, 0x99, 0x3a, 0x4b, 0xf7, 0x4e, 0xb0, 0xf2, 0x34, 0x54, 0x83, 0x86, 0x4c, 0x77, 0x16, 0x94, 0xbc, 0x36, 0xb0, 0x61, 0xe9, 0x07, 0x07, 0xcc, 0x65, 0x77, 0xb1, 0x1d, 0x8f, 0x7e, 0x39, 0x6d, 0xc4, 0xba, 0x80, 0xdb, 0x8f, 0xea, 0x58, 0xca, 0x34, 0x7b, 0xd3, 0xf2, 0x92, 0xb9, 0x57, 0xb9, 0x81, 0x84, 0x04, 0xc5, 0x76, 0xc7, 0x2e, 0xc2, 0x12, 0x51, 0x67, 0x9f, 0xc3, 0x47, 0x0a, 0x0c, 0x29, 0xb5, 0x9d, 0x39, 0xbb, 0x92, 0x15, 0xc6, 0x9f, 0x2f, 0x31, 0xe0, 0x9a, 0x54, 0x35, 0xda, 0xb9, 0x10, 0x7d, 0x32, 0x19, 0x16 }
   };
  // Xor in the last block.
  #pragma unroll
  for (size_t i = 0; i < sizes[variant]; i++) { ((uint64_t *)(a[variant]))[i] ^= ((uint64_t *)(in))[i]; } \
  // Apply P
  P(a[variant]);
  // Squeeze output.
  #pragma unroll
  for (size_t i = 0; i < 8; i++) ((uint32_t *)out)[i] = ((uint32_t *)(a[variant]))[i];
  return 0;
}

/* RANDOM NUMBER GENERATOR BASED ON MWC64X                          */
/* http://cas.ee.ic.ac.uk/people/dt10/research/rngs-gpu-mwc64x.html */

/*  Written in 2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>. */


/* This is xoshiro256** 1.0, one of our all-purpose, rock-solid
   generators. It has excellent (sub-ns) speed, a state (256 bits) that is
   large enough for any parallel application, and it passes all tests we
   are aware of.

   For generating just floating-point numbers, xoshiro256+ is even faster.

   The state must be seeded so that it is not everywhere zero. If you have
   a 64-bit seed, we suggest to seed a splitmix64 generator and use its
   output to fill s. */

inline uint64_t rotl(const uint64_t x, int k) {
	return (x << k) | (x >> (64 - k));
}

inline uint64_t xoshiro256_next(global ulong4 *s) {
	const uint64_t result = rotl(s->y * 5, 7) * 9;

	const uint64_t t = s->y << 17;

	s->z ^= s->x;
	s->w ^= s->y;
	s->y ^= s->z;
	s->x ^= s->w;

	s->z ^= t;

	s->w = rotl(s->w, 45);

	return result;
}
/* KERNEL CODE */

#ifdef cl_khr_int64_base_atomics
#pragma OPENCL EXTENSION cl_khr_int64_base_atomics: enable
#endif

typedef uint8_t Hash[32];
typedef uint64_t uint256_t[4];

#define BLOCKDIM 1024
#define MATRIX_SIZE 64
#define HALF_MATRIX_SIZE 32
#define QUARTER_MATRIX_SIZE 16
#define HASH_HEADER_SIZE 72

#define LT_U256(X,Y) (X[3] != Y[3] ? X[3] < Y[3] : X[2] != Y[2] ? X[2] < Y[2] : X[1] != Y[1] ? X[1] < Y[1] : X[0] < Y[0])

#ifndef cl_khr_int64_base_atomics
global int lock = false;
#endif

uint32_t STATIC inline amul4bit(constant uint32_t packed_vec1[32], uint32_t packed_vec2[32]) {
    // We assume each 32 bits have four values: A0 B0 C0 D0
    uint32_t res = 0;
    #pragma unroll
    for (int i=0; i<QUARTER_MATRIX_SIZE; i++) {
        #if __PLATFORM__ == NVIDIA_CUDA && (__COMPUTE_MAJOR__ > 6 || (__COMPUTE_MAJOR__ == 6 && __COMPUTE_MINOR__ >= 1))
        asm("dp4a.u32.u32" " %0, %1, %2, %3;": "=r" (res): "r" (packed_vec1[i]), "r" (packed_vec2[i]), "r" (res));
        #elif defined(__gfx906__) || defined(__gfx908__) || defined(__gfx1011__) || defined(__gfx1012__) || defined(__gfx1030__) || defined(__gfx1031__) || defined(__gfx1032__)
        __asm__("v_dot4_u32_u8" " %0, %1, %2, %3;": "=v" (res): "r" (packed_vec1[i]), "r" (packed_vec2[i]), "r" (res));
        #else
        res += ((constant char4 *)packed_vec1)[i].x*((char4 *)packed_vec2)[i].x;
        res += ((constant char4 *)packed_vec1)[i].y*((char4 *)packed_vec2)[i].y;
        res += ((constant char4 *)packed_vec1)[i].z*((char4 *)packed_vec2)[i].z;
        res += ((constant char4 *)packed_vec1)[i].w*((char4 *)packed_vec2)[i].w;
        #endif
    }

    return res;
}

STATIC inline void heavy_hash(
    __constant const uint8_t hash_header[HASH_HEADER_SIZE],
    __constant const uint8_t matrix[MATRIX_SIZE][MATRIX_SIZE],
    __constant const uint256_t target,
    private const uint64_t nonce,
    volatile global uint64_t *final_nonce,
    volatile global uint64_t *final_hash
) {

    int64_t buffer[10];

    // header
    for(int i=0; i<9; i++) buffer[i] = ((__constant const int64_t *)hash_header)[i];
    // data
    buffer[9] = nonce;

    Hash hash_;
    hash(0, hash_, (uint8_t *) buffer);

    private uchar hash_part[64];
    for (int i=0; i<32; i++) {
         hash_part[2*i] = (hash_[i] & 0xF0) >> 4;
         hash_part[2*i+1] = hash_[i] & 0x0F;
    }

    for (int rowId=0; rowId<32; rowId++){
        uint32_t product1 = amul4bit((constant uint32_t *)matrix[(2*rowId)], (private uint32_t *)hash_part);
        uint32_t product2 = amul4bit((constant uint32_t *)matrix[(2*rowId+1)], (private uint32_t *)hash_part);

        product1 >>= 10;
        product2 >>= 10;
        hash_[rowId] ^= (uint8_t)((product1 << 4) | (uint8_t)(product2));
    }

    hash(1, hash_, hash_);
    if (LT_U256(((uint64_t *)hash_), target)){
        //printf("%lu: %lu < %lu: %d %d\n", nonce, ((uint64_t *)hash_)[3], target[3], ((uint64_t *)hash_)[3] < target[3], LT_U256((uint64_t *)hash_, target));
        #ifdef cl_khr_int64_base_atomics
        atom_cmpxchg(final_nonce, 0, nonce);
        #else
        if (!atom_cmpxchg(&lock, 0, 1)) {
            *final_nonce = nonce;
            //for(int i=0;i<4;i++) final_hash[i] = ((uint64_t volatile *)hash_)[i];
        }
        #endif
    }
    /*if (nonceId==1) {
        //printf("%lu: %lu < %lu: %d %d\n", nonce, ((uint64_t *)hash2_)[3], target[3], ((uint64_t *)hash_)[3] < target[3]);
        *final_nonce = nonce;
        for(int i=0;i<4;i++) final_hash[i] = ((uint64_t volatile *)hash_)[i];
    }*/
}

kernel void heavy_hash_xoshiro(
     __constant const uint8_t hash_header[HASH_HEADER_SIZE],
     __constant const uint8_t matrix[MATRIX_SIZE][MATRIX_SIZE],
     __constant const uint256_t target,
     global ulong4 *random_state,
     volatile global uint64_t *final_nonce,
     volatile global uint64_t *final_hash
 ) {
    int nonceId = get_global_id(0);

    #ifndef cl_khr_int64_base_atomics
    if (nonceId == 0)
       lock = 0;
    work_group_barrier(CLK_GLOBAL_MEM_FENCE);
    #endif

    private uint64_t nonce = xoshiro256_next(random_state + nonceId);

    heavy_hash(hash_header, matrix, target, nonce, final_nonce, final_hash);
 }

 kernel void heavy_hash_lean(
      __constant const uint8_t hash_header[HASH_HEADER_SIZE],
      __constant const uint8_t matrix[MATRIX_SIZE][MATRIX_SIZE],
      __constant const uint256_t target,
      global uint64_t *seed,
      volatile global uint64_t *final_nonce,
      volatile global uint64_t *final_hash
  ) {
     int nonceId = get_global_id(0);

     #ifndef cl_khr_int64_base_atomics
     if (nonceId == 0)
        lock = 0;
     work_group_barrier(CLK_GLOBAL_MEM_FENCE);
     #endif

     private uint64_t nonce = seed[0] + nonceId;
     heavy_hash(hash_header, matrix, target, nonce, final_nonce, final_hash);
  }