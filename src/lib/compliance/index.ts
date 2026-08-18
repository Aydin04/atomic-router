export interface AuditLogEntry {
  id?: string;
  timestamp?: string;
  action?: string;
  resource?: string;
  user?: string;
  details?: any;
}

export function logAuditEvent(..._args: any[]): void {}
export function getAuditRequestContext(..._args: any[]): any {
  return {};
}
export function getAuditLog(..._args: any[]): any[] {
  return [];
}
export function countAuditLog(..._args: any[]): number {
  return 0;
}
