import * as dns from 'dns';

/**
 * Algunas redes/PC (p. ej. Windows con DNS local) hacen que el resolver de Node
 * rechace las consultas SRV que necesita `mongodb+srv://`. Si se define
 * DNS_SERVERS (lista separada por comas, p. ej. "8.8.8.8,1.1.1.1"), Node usa esos
 * servidores. Si no se define, no se toca nada.
 */
export function configurarDns(): void {
  const servidores = (process.env.DNS_SERVERS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (servidores.length > 0) {
    dns.setServers(servidores);
  }
}
