#pragma once
#include <stddef.h>
#include "bw.h"

typedef struct bwPool {
	void* first;
	size_t elementSize;
	size_t size;
	size_t capacity;
	size_t* recycledIndices;
	size_t recycledCount;
} bwPool;

// Initializes a pool with a given capacity.
BW_EXPORT void bwPool_Init(bwPool* pPool, size_t elementSize, size_t capacity);

// Gets an element from the pool.
BW_EXPORT void* bwPool_Get(bwPool* pPool, size_t index);

// Adds an element to the pool. Returns the index of the added element.
BW_EXPORT size_t bwPool_Add(bwPool* pPool);

// Removes an element from the pool.
BW_EXPORT void bwPool_Remove(bwPool* pPool, size_t index);

BW_EXPORT void bwPool_Truncate(bwPool* pPool, size_t newSize);