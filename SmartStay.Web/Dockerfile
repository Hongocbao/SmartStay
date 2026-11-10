FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY SmartStay.Web/SmartStay.Web.csproj SmartStay.Web/
RUN dotnet restore SmartStay.Web/SmartStay.Web.csproj

COPY SmartStay.Web/ SmartStay.Web/
COPY database/ database/
RUN dotnet publish SmartStay.Web/SmartStay.Web.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:10000
EXPOSE 10000
COPY --from=build /src/database /database
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "SmartStay.Web.dll"]
