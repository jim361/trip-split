import type { ReactNode } from "react";

export interface FeaturePlaceholderProps {
  title: string;
  description: string;
  children?: ReactNode;
  statusLabel?: string;
  eyebrow?: string;
  compactHeader?: boolean;
  headerActions?: ReactNode;
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
  compactHeader = false,
  headerActions,
}: FeaturePlaceholderProps) {
  return (
    <article
      className={`feature-page${compactHeader ? " feature-page--compact" : ""}`}
      aria-labelledby="feature-page-title"
    >
      <header className="feature-page__header">
        <div>
          {!compactHeader ? <p className="eyebrow">{eyebrow}</p> : null}
          <h1 id="feature-page-title">{title}</h1>
          {!compactHeader ? <p className="feature-page__description">{description}</p> : null}
        </div>
        <span className="data-status" role="status">
          <span className="data-status__dot" aria-hidden="true" />
          {statusLabel}
        </span>
        {headerActions ? <div className="feature-page__actions">{headerActions}</div> : null}
      </header>

      <div className="feature-page__content">{children}</div>
    </article>
  );
}
