import { Controller, Get } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';

@Controller('health')
export class HealthController {
  @Public()
  @Get()
  getHealth() {
    return {
      success: true,
      message: 'Ghiyarak backend is running',
      data: {
        service: 'backend',
        status: 'healthy',
      },
    };
  }
}
