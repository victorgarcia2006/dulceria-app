import { IsOptional, Matches } from 'class-validator';

const FORMATO = /^\d{4}-\d{2}-\d{2}$/;

export class ListSalesQuery {
  /** Un solo día (YYYY-MM-DD, hora de Ciudad de México). Tiene prioridad sobre from/to. */
  @IsOptional()
  @Matches(FORMATO, { message: 'date debe tener formato YYYY-MM-DD' })
  date?: string;

  /** Desde este día, inclusive (YYYY-MM-DD, hora de Ciudad de México). */
  @IsOptional()
  @Matches(FORMATO, { message: 'from debe tener formato YYYY-MM-DD' })
  from?: string;

  /** Hasta este día, inclusive (YYYY-MM-DD, hora de Ciudad de México). */
  @IsOptional()
  @Matches(FORMATO, { message: 'to debe tener formato YYYY-MM-DD' })
  to?: string;
}
