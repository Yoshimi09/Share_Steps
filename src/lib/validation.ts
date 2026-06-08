export function parseNonNegativeInteger(value: string, label: string) {
  if (!/^\d+$/.test(value.trim())) {
    throw new Error(`${label}は0以上の整数で入力してください。`);
  }

  return Number(value);
}

export function parsePositiveInteger(value: string, label: string) {
  if (!/^\d+$/.test(value.trim())) {
    throw new Error(`${label}は1以上の整数で入力してください。`);
  }

  const parsed = Number(value);
  if (parsed < 1) {
    throw new Error(`${label}は1以上の整数で入力してください。`);
  }

  return parsed;
}
