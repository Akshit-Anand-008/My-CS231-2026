#include <map>
#include <vector>

#include "cache.h"

// One 8-bit counter per instruction, indexed by the lower 16 bits of its ip.
// A high count means lines brought in by that instruction are reused.
std::map<CACHE*, std::vector<uint8_t>> pcCount;

// index into pcCount: the lower 16 bits of the ip
uint32_t pc_index(uint64_t ip) { return ip & 0xFFFF; }

// called once before the simulation starts
void CACHE::initialize_replacement()
{
  // TODO: give pcCount[this] 1 << 16 counters, all 0
}

// called when the set is full: return the way to evict
uint32_t CACHE::find_victim(uint32_t cpu, uint64_t instr_id, uint32_t set, const BLOCK* current_set, uint64_t ip, uint64_t full_addr, uint32_t type)
{
  // current_set[i].ip is the ip of the instruction that brought line i in.
  // TODO: return the way whose ip has the lowest count; on a tie, the lowest way
  return 0;
}

// called on every hit (hit = 1) and every fill (hit = 0) of the line in (set, way)
void CACHE::update_replacement_state(uint32_t cpu, uint32_t set, uint32_t way, uint64_t full_addr, uint64_t ip, uint64_t victim_addr, uint32_t type,
                                     uint8_t hit)
{
  // a writeback hit is the upper cache handing back a dirty line, not a use by the program
  if (hit && type == WRITEBACK)
    return;

  // TODO: the counter of this ip goes up by 1 on a hit (at most 255)
  //       and down by 1 on a fill (at least 0)
}

// called once at the end of the simulation
void CACHE::replacement_final_stats() {}
