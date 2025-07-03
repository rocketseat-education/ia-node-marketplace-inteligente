import { Module } from '@nestjs/common';
import { CatalogModule } from './catalog/catalog.module';
import { ConfigModule } from '@nestjs/config';
import { CartModule } from './cart/cart.module';
import { ChatModule } from './chat/chat.module';

@Module({
  imports: [
    CatalogModule,
    ConfigModule.forRoot({ isGlobal: true }),
    CartModule,
    ChatModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
