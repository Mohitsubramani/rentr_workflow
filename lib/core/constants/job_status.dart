enum JobStatus {
  open,
  applied,
  assigned,
  inProgress,
  completed,
}

extension JobStatusX on JobStatus {
  String get value {
    switch (this) {
      case JobStatus.open:
        return 'open';
      case JobStatus.applied:
        return 'applied';
      case JobStatus.assigned:
        return 'assigned';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
    }
  }

  static JobStatus fromString(String status) {
    switch (status) {
      case 'applied':
        return JobStatus.applied;
      case 'assigned':
        return JobStatus.assigned;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      default:
        return JobStatus.open;
    }
  }
}
