import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { PrismaModule } from '../../prisma/prisma.module';
import { CatalogController } from './catalog.controller';
import { CatalogService } from './catalog.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Module({
	imports: [
		PrismaModule,
		ConfigModule,
		JwtModule.registerAsync({
			imports: [ConfigModule],
			inject: [ConfigService],
			useFactory: (config: ConfigService) => ({
				secret: config.get<string>('JWT_ACCESS_SECRET'),
			}),
		}),
	],
	controllers: [CatalogController],
	providers: [CatalogService, JwtAuthGuard, Reflector],
	exports: [CatalogService],
})
export class CatalogModule {}
