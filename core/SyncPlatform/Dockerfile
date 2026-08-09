# syntax=docker/dockerfile:1.7
# Dockerfile .NET dùng chung cho Gateway + 9 microservices.
# Build context = core/SyncPlatform (để restore được project references / Libs.*).
# Truyền: --build-arg PROJECT=<đường-dẫn-csproj tính từ core/SyncPlatform>
# vd: --build-arg PROJECT=src/Services/Iam/Iam.API/Iam.API.csproj
ARG DOTNET_VERSION=10.0

FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}-noble AS build
ARG PROJECT
WORKDIR /src
COPY . .
RUN dotnet restore "$PROJECT"
RUN dotnet publish "$PROJECT" -c Release -o /app /p:UseAppHost=false
# Chuẩn hoá entrypoint thành app.dll (chiseled không có shell để chạy dll động).
# Phải copy CẢ runtimeconfig.json + deps.json, nếu không `dotnet app.dll` sẽ không
# thấy app.runtimeconfig.json → chạy nhầm self-contained → thiếu libhostpolicy.so.
RUN set -eux; ASSEMBLY="$(basename "$PROJECT" .csproj)"; \
    cp "/app/$ASSEMBLY.dll" /app/app.dll; \
    cp "/app/$ASSEMBLY.runtimeconfig.json" /app/app.runtimeconfig.json; \
    cp "/app/$ASSEMBLY.deps.json" /app/app.deps.json

FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_VERSION}-noble-chiseled AS runtime
ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_gcServer=1 \
    DOTNET_EnableDiagnostics=0
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "app.dll"]
