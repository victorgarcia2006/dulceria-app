import 'reflect-metadata';
import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { configurarDns } from './common';

configurarDns();

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');
  // CORS abierto: el frontend (Flutter Web) corre en otro origen.
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const puerto = Number(process.env.PORT) || 3000;
  await app.listen(puerto, '0.0.0.0');
  console.log(`API de la dulcería escuchando en http://0.0.0.0:${puerto}/api`);
}

bootstrap();
