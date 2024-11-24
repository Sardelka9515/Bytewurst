#pragma once
#include <stddef.h>
typedef struct bwPool {
	void* first;
	size_t elementSize;
	size_t count;
	size_t capacity;
	size_t* recycledIndices;
	size_t recycledCount;
} bwPool;

// Initializes a pool with a given capacity.
void bwPool_Init(bwPool* pPool, size_t elementSize, size_t capacity);

// Gets an element from the pool.
void* bwPool_Get(bwPool* pPool, size_t index);

// Adds an element to the pool. Returns the index of the added element.
size_t bwPool_Add(bwPool* pPool, void* pElement);

// Removes an element from the pool.
void bwPool_Remove(bwPool* pPool, size_t index);