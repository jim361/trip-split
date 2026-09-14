import type { ReactNode } from "react";

export interface PlaceholderPanelProps {
  title: string;
  description: string;
  children?: ReactNode;
  className?: string;
}

export function PlaceholderPanel({
  title,
  description,
  children,
  className = "",
}: PlaceholderPanelProps) {
  const classes = ["placeholder-panel", className].filter(Boolean).join(" ");

  return (
    <section className={classes} aria-label={title}>
      <div className="placeholder-panel__heading">
        <h2>{title}</h2>
        <p>{description}</p>
      </div>
      {children}
    </section>
  );
}
