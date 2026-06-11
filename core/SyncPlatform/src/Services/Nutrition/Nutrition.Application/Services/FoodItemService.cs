using Libs.Shared.Enums;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;
using Nutrition.Application.Exceptions;
using Nutrition.Application.Helpers;
using Nutrition.Application.Mappers;
using Nutrition.Domain.Common;
using Nutrition.Domain.Enums;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Application.Services;

public class FoodItemService : IFoodItemService
{
    private readonly IFoodItemRepository _repository;

    public FoodItemService(IFoodItemRepository repository)
    {
        _repository = repository;
    }

    public async Task<(IReadOnlyList<FoodItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        FoodSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var criteria = new FoodItemSearchCriteria
        {
            Query = request.Query,
            PageNumber = pageNumber,
            PageSize = pageSize,
        };

        if (!string.IsNullOrWhiteSpace(request.Category)
            && Enum.TryParse<FoodCategory>(request.Category, true, out var category))
        {
            criteria.Category = category;
        }

        if (request.DietaryTags is { Count: > 0 })
        {
            var tags = new List<DietaryTag>();
            foreach (var tag in request.DietaryTags)
            {
                if (Enum.TryParse<DietaryTag>(tag, true, out var parsed))
                    tags.Add(parsed);
            }

            if (tags.Count > 0)
                criteria.DietaryTags = tags;
        }

        var (entities, totalRecords) = await _repository.SearchPagedAsync(criteria, cancellationToken);
        var dtos = entities.Select(e => e.ToDto()).ToList();
        return (dtos, new PaginationMetadata(pageNumber, pageSize, totalRecords));
    }

    public async Task<FoodItemDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null || !entity.IsActive)
            throw new NotFoundException(nameof(FoodItem), id);
        return entity.ToDto();
    }

    public async Task<FoodItemDto> GetByBarcodeAsync(string barcode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(barcode))
            throw new BadRequestException("Barcode is required.");

        var entity = await _repository.GetByBarcodeAsync(barcode.Trim(), cancellationToken);
        if (entity == null || !entity.IsActive)
            throw new NotFoundException(nameof(FoodItem), barcode);
        return entity.ToDto();
    }

    public async Task<FoodItemDto> CreateUserSubmittedAsync(
        Guid userId,
        CreateUserFoodItemDto dto,
        CancellationToken cancellationToken = default)
    {
        _ = userId;
        ValidateFoodMacros(dto.CaloriesPer100g, dto.ServingSizeGram);

        if (string.IsNullOrWhiteSpace(dto.NameVi) && string.IsNullOrWhiteSpace(dto.NameEn))
            throw new BadRequestException("NameVi or NameEn is required.");

        var name = !string.IsNullOrWhiteSpace(dto.NameVi) ? dto.NameVi : dto.NameEn;
        var entity = new FoodItem
        {
            NameVi = dto.NameVi.Trim(),
            NameEn = string.IsNullOrWhiteSpace(dto.NameEn) ? dto.NameVi.Trim() : dto.NameEn.Trim(),
            Slug = NutritionMacroCalculator.SlugFromName(name),
            Category = dto.Category,
            Brand = dto.Brand?.Trim(),
            Barcode = string.IsNullOrWhiteSpace(dto.Barcode) ? null : dto.Barcode.Trim(),
            ServingSizeGram = dto.ServingSizeGram,
            ServingDescription = dto.ServingDescription,
            CaloriesPer100g = dto.CaloriesPer100g,
            ProteinPer100g = dto.ProteinPer100g,
            CarbPer100g = dto.CarbPer100g,
            FatPer100g = dto.FatPer100g,
            FiberPer100g = dto.FiberPer100g,
            SugarPer100g = dto.SugarPer100g,
            SodiumMgPer100g = dto.SodiumMgPer100g,
            DietaryTags = dto.DietaryTags ?? [],
            ImageUrl = dto.ImageUrl,
            Source = FoodDataSource.UserSubmitted,
            IsVerified = false,
            IsActive = true,
        };

        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<int> ImportSystemFoodsAsync(
        ImportSystemFoodItemsRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Items.Count == 0)
            throw new BadRequestException("At least one food item is required.");

        var imported = 0;
        foreach (var item in request.Items)
        {
            ValidateFoodMacros(item.CaloriesPer100g, item.ServingSizeGram);
            var entity = new FoodItem
            {
                NameVi = item.NameVi.Trim(),
                NameEn = item.NameEn.Trim(),
                Slug = string.IsNullOrWhiteSpace(item.Slug)
                    ? NutritionMacroCalculator.SlugFromName(item.NameEn)
                    : item.Slug.Trim().ToLowerInvariant(),
                Category = item.Category,
                Brand = item.Brand?.Trim(),
                Barcode = string.IsNullOrWhiteSpace(item.Barcode) ? null : item.Barcode.Trim(),
                ServingSizeGram = item.ServingSizeGram,
                ServingDescription = item.ServingDescription,
                CaloriesPer100g = item.CaloriesPer100g,
                ProteinPer100g = item.ProteinPer100g,
                CarbPer100g = item.CarbPer100g,
                FatPer100g = item.FatPer100g,
                DietaryTags = item.DietaryTags ?? [],
                ImageUrl = item.ImageUrl,
                Source = FoodDataSource.System,
                IsVerified = item.IsVerified,
                IsActive = true,
            };

            await _repository.CreateAsync(entity, cancellationToken);
            imported++;
        }

        return imported;
    }

    private static void ValidateFoodMacros(int caloriesPer100g, decimal servingSizeGram)
    {
        if (caloriesPer100g < 0)
            throw new BadRequestException("CaloriesPer100g must be non-negative.");
        if (servingSizeGram <= 0)
            throw new BadRequestException("ServingSizeGram must be greater than zero.");
    }
}
