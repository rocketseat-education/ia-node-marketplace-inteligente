import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client } from 'pg';

@Injectable()
export class PostgresService implements OnApplicationBootstrap {
  client: Client;
  logger = new Logger(PostgresService.name);

  constructor(private readonly configService: ConfigService) {
    this.client = new Client({
      user: this.configService.getOrThrow('POSTGRES_USER'),
      host: this.configService.getOrThrow('POSTGRES_HOST'),
      database: this.configService.getOrThrow('POSTGRES_DB'),
      password: this.configService.getOrThrow('POSTGRES_PASSWORD'),
      port: parseInt(this.configService.getOrThrow('POSTGRES_PORT'), 10),
    });
  }

  onApplicationBootstrap() {
    return this.client
      .connect()
      .then(() => this.logger.log('Postgres connected successfully'))
      .catch((err) => this.logger.error('Postgres connection error', err));
  }
}
