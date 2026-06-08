import type { ReactNode } from 'react';

type StatCardProps = {
  label: string;
  value: string;
  detail?: string;
  icon?: ReactNode;
};

export function StatCard({ label, value, detail, icon }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className="stat-card-header">
        <span>{label}</span>
        {icon}
      </div>
      <strong>{value}</strong>
      {detail ? <p>{detail}</p> : null}
    </div>
  );
}
