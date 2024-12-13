#include "pool.h"
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

void bwPool_Init(bwPool* pPool, size_t elementSize, size_t capacity) {
	pPool->first = malloc(capacity * elementSize);
	pPool->elementSize = elementSize;
	pPool->size = 0;
	pPool->capacity = capacity;
	pPool->recycledIndices = (size_t*)malloc(capacity * sizeof(size_t));
	pPool->recycledCount = 0;
}

void* bwPool_Get(bwPool* pPool, size_t index) {
	if (index > pPool->size) {
		assert(0);
		return NULL;
	}
	return (void*)((char*)pPool->first + index * pPool->elementSize);
}

size_t bwPool_Add(bwPool* pPool) {
	if (pPool->recycledCount > 0) {
		size_t index;
		do {
			if (pPool->recycledCount == 0) {
				goto add;
			}
			index = pPool->recycledIndices[--pPool->recycledCount];
		} while (index >= pPool->size); // Pool may be truncated
		return index;
	}
add:
	if (pPool->size >= pPool->capacity) {
		assert(0);
		return -1;
	}
	size_t index = pPool->size++;
	memset(bwPool_Get(pPool, index), 0, pPool->elementSize);
	return index;
}

void bwPool_Remove(bwPool* pPool, size_t index) {
	if (index >= pPool->size) {
		assert(0);
		return;
	}
	if (index == pPool->size - 1) {
		pPool->size--;
		return;
	}
	else {
		pPool->recycledIndices[pPool->recycledCount++] = index;
		memset(bwPool_Get(pPool, index), 0, pPool->elementSize);
	}
}

void bwPool_Truncate(bwPool* pPool, size_t newSize) {
	if (newSize > pPool->size) {
		assert(0);
		return;
	}
	pPool->size = newSize;
}