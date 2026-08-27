import type { ReactNode } from "react";

export interface FeaturePlaceholderProps {
  title: string;
  description: string;
  children?: ReactNode;
  statusLabel?: string;
  eyebrow?: string;
}

/**
 * A semantic hand-off surface for feature teams. Domain screens can replace
 * the children without changing TripShell or the shared route contract.
 */
export function FeaturePlaceholder({
  title,
  description,
  children,
  statusLabel = "Mock repository 연결 준비됨",
  eyebrow = "여행 워크스페이스",
}: FeaturePlaceholderProps) {
  return (
    <article className="feature-page" aria-labelledby="feature-page-title">
      <header className="feature-page__header">
        <div>
          <p className="eyebrow">{eyebrow}</p>
          <h1 id="feature-page-title">{title}</h1>
          <p className="feature-page__description">{description}</p>
        </div>
        <span className="data-status" role="status">
          <span className="data-status__dot" aria-hidden="true" />
          {statusLabel}
        </span>
      </header>

      <div className="feature-page__content">{children}</div>
    </article>
  );
}
