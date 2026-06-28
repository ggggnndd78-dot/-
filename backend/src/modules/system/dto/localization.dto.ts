import { IsIn } from 'class-validator';

export class UpdateUserLocaleDto {
  @IsIn(['ar', 'en'])
  locale!: 'ar' | 'en';
}
