/// Per-node trace emitted by knowledge ranking.
class CoachKnowledgeNodeTrace {
  const CoachKnowledgeNodeTrace({
    required this.nodeId,
    required this.score,
    required this.matchedEntities,
    required this.matchedGoals,
    required this.matchedRestrictions,
    required this.matchedEquipment,
    required this.matchedMemory,
    required this.matchedIntent,
    required this.reasons,
  });

  final String nodeId;
  final double score;
  final List<String> matchedEntities;
  final List<String> matchedGoals;
  final List<String> matchedRestrictions;
  final List<String> matchedEquipment;
  final List<String> matchedMemory;
  final bool matchedIntent;
  final List<String> reasons;
}

/// Full trace for one knowledge runtime execution.
class CoachKnowledgeTrace {
  const CoachKnowledgeTrace({
    required this.nodeTraces,
    required this.executionTime,
    required this.selectedNodeId,
    required this.usedFallback,
  });

  final List<CoachKnowledgeNodeTrace> nodeTraces;
  final Duration executionTime;
  final String selectedNodeId;
  final bool usedFallback;

  CoachKnowledgeNodeTrace? traceFor(String nodeId) {
    for (final trace in nodeTraces) {
      if (trace.nodeId == nodeId) return trace;
    }
    return null;
  }
}
