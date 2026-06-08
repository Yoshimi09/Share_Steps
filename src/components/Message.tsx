type MessageProps = {
  message: string | null;
  tone?: 'error' | 'success' | 'info';
};

export function Message({ message, tone = 'info' }: MessageProps) {
  if (!message) {
    return null;
  }

  return <p className={`message message-${tone}`}>{message}</p>;
}
