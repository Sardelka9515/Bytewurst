#include "pool.h"
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

void bwPool_Init(bwPool* pPool, size_t elementSize, size_t capacity) {
	pPool->first = malloc(capacity * sizeof(void*));
	pPool->elementSize = elementSize;
	pPool->count = 0;
	pPool->capacity = capacity;
	pPool->recycledIndices = malloc(capacity * sizeof(size_t));
	pPool->recycledCount = 0;
}

void* bwPool_Get(bwPool* pPool, size_t index) {
	if (index > pPool->count) {
		return NULL;
	}
	return (void*)((char*)pPool->first + index * pPool->elementSize);
}

size_t bwPool_Add(bwPool* pPool, void* pElement) {
	if (pPool->recycledCount > 0) {
		size_t index = pPool->recycledIndices[--pPool->recycledCount];
		return index;
	}
	if (pPool->count >= pPool->capacity) {
		return -1;
	}
	return pPool->count++;
}

void bwPool_Remove(bwPool* pPool, size_t index) {
	if (index >= pPool->count) {
		return;
	}
	pPool->recycledIndices[pPool->recycledCount++] = index;
	memset((char*)pPool->first + pPool->elementSize * index, 0, pPool->elementSize);
}