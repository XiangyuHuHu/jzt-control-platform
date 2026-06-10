const normalizedBase = import.meta.env.BASE_URL.replace(/\/$/, '')

export const withApiBase = (path: string) => {
  if (!path.startsWith('/')) {
    return `${normalizedBase}/${path}`
  }

  return `${normalizedBase}${path}`
}
