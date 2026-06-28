"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrganizationsModule = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const core_1 = require("@nestjs/core");
const event_bus_module_1 = require("../../common/events/event-bus.module");
const audit_module_1 = require("../audit/audit.module");
const communications_module_1 = require("../communications/communications.module");
const notifications_module_1 = require("../notifications/notifications.module");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const organizations_controller_1 = require("./organizations.controller");
const organizations_service_1 = require("./organizations.service");
let OrganizationsModule = class OrganizationsModule {
};
exports.OrganizationsModule = OrganizationsModule;
exports.OrganizationsModule = OrganizationsModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule,
            audit_module_1.AuditModule,
            notifications_module_1.NotificationsModule,
            communications_module_1.CommunicationsModule,
            event_bus_module_1.EventBusModule,
            jwt_1.JwtModule.registerAsync({
                imports: [config_1.ConfigModule],
                inject: [config_1.ConfigService],
                useFactory: (config) => ({
                    secret: config.get('JWT_ACCESS_SECRET'),
                }),
            }),
        ],
        controllers: [organizations_controller_1.OrganizationsController],
        providers: [organizations_service_1.OrganizationsService, jwt_auth_guard_1.JwtAuthGuard, core_1.Reflector],
    })
], OrganizationsModule);
