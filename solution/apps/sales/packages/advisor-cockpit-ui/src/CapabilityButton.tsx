import * as React from 'react';
import { Button, Tooltip, type ButtonProps } from '@fluentui/react-components';
import { isCapabilityExecutable, type CommandCapability } from '@crmshow/advisor-cockpit-domain';

export interface CapabilityButtonProps {
  capability: CommandCapability;
  children: React.ReactNode;
  appearance?: ButtonProps['appearance'];
  className?: string;
  disabled?: boolean;
  icon?: ButtonProps['icon'];
  onClick?: () => void;
  size?: ButtonProps['size'];
  style?: React.CSSProperties;
}

export function CapabilityButton({
  capability,
  children,
  appearance,
  className,
  disabled,
  icon,
  onClick,
  size,
  style,
}: CapabilityButtonProps): JSX.Element {
  const unavailable = !isCapabilityExecutable(capability);

  if (!unavailable) {
    return (
      <Button
        appearance={appearance}
        className={className}
        disabled={disabled}
        icon={icon}
        onClick={onClick}
        size={size}
        style={style}
      >
        {children}
      </Button>
    );
  }

  const preventUnavailable = (event: React.SyntheticEvent) => {
    event.preventDefault();
    event.stopPropagation();
  };
  const accessibleName = typeof children === 'string' ? children : undefined;

  return (
    <Tooltip content={capability.reason} relationship="description">
      <span
        aria-description={capability.reason}
        aria-disabled="true"
        aria-label={accessibleName}
        role="button"
        tabIndex={0}
        onClick={preventUnavailable}
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') preventUnavailable(event);
        }}
        style={{ display: 'inline-flex' }}
      >
        <Button
          appearance={appearance}
          aria-hidden="true"
          className={className}
          icon={icon}
          size={size}
          style={style}
          tabIndex={-1}
          onClick={preventUnavailable}
        >
          {children}
        </Button>
      </span>
    </Tooltip>
  );
}