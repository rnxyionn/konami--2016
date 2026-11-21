using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc;
using Roblox.Dto.Games;
using Roblox.Exceptions;
using Roblox.Models.Assets;
using Roblox.Models.Groups;
using Roblox.Services.App.FeatureFlags;
using Roblox.Services.Exceptions;
using Type = Roblox.Models.Assets.Type;

namespace Roblox.Website.Controllers;

[ApiController]
[Route("/apisite/games/v1")]
public class GamesControllerV1 : ControllerBase
{
    private async Task<Roblox.Dto.Games.MultiGetUniverseEntry> GetEditableUniverse(long universeId)
    {
        var universe = (await services.games.MultiGetUniverseInfo(new[] {universeId})).FirstOrDefault();
        if (universe == null)
            throw new RecordNotFoundException();

        if (universe.creatorType == CreatorType.User)
        {
            if (universe.creatorId != safeUserSession.userId)
                throw new ForbiddenException();
        }
        else if (!await services.groups.DoesUserHavePermission(safeUserSession.userId, universe.creatorId,
                     GroupPermission.ManageGroupGames))
        {
            throw new ForbiddenException();
        }

        return universe;
    }

    [HttpGet("games")]
    public async Task<dynamic> MultiGetUniverseInfo(string universeIds)
    {
        var sp = universeIds.Split(",").Select(long.Parse);
        var result = await services.games.MultiGetUniverseInfo(sp);
        return new
        {
            data = result,
        };
    }

    [HttpGet("games/sorts")]
    public async Task<dynamic> GetGameSorts(string? gameSortsContext)
    {
        var sorts = new Dictionary<string, dynamic>()
        {
            {
                "popular", new
                {
                    token = "popular",
                    name = "popular",
                    displayName = "popular",
                }
            },
            {
                "recent", new
                {
                    token = "recent",
                    name = "Recent",
                    displayName = "Recent",
                }
            },
            {
                "mostFavorited", new
                {
                    token = "mostFavorited",
                    name = "Most Favorited",
                    displayName = "Most Favorited",
                }
            },
            {
                "recentlyUpdated", new
                {
                    token = "recentlyUpdated",
                    name = "Recently Updated",
                    displayName = "Recently Updated",
                }
            },
            {
                "recentlyCreated", new
                {
                    token = "recentlyCreated",
                    name = "Recently Created",
                    displayName = "Recently Created",
                }
            },
        };

        var results = new List<dynamic>();
        if (gameSortsContext == "HomeSorts")
        {
            if (userSession == null)
                throw new ForbiddenException();
            // we need to check if player actually has anything recent before showing recent sort
            var recent = await services.games.GetRecentGames(userSession.userId, 1);
            if (recent.Any())
            {
                results.Add(sorts["recent"]);
                results.Add(sorts["popular"]);
                // results.Add(sorts["mostFavorited"]);
            }
        }
        else
        {
            results.Add(sorts["popular"]);
            results.Add(sorts["mostFavorited"]);
            results.Add(sorts["recentlyUpdated"]);
            // results.Add(sorts["recentlyCreated"]);
        }

        return new
        {
            sorts = results.Select(c => new
            {
                c.token,
                c.name,
                c.displayName,
                getSetTypeId = 0,
                gameSetTargetId = 0,
                timeOptionsAvailable = false,
                genreOptionsAvailable = false,
                numberOfRows = 1,
                numberOfGames = 0,
                isDefaultSort = true,
                contextUniverseId = (long?) null,
                contextCountryRegionId = (int?) null,
                tokenExpiryInSeconds = 86400,
            }),
        };
    }

    [HttpGet("games/list")]
    public async Task<dynamic> GetGamesList(string? sortToken, int maxRows = 10, Genre? genre = null, string? keyword = null)
    {
        if (maxRows is > 100 or < 1) maxRows = 10;
        var result = await services.games.GetGamesList(userSession?.userId, sortToken, maxRows, genre, keyword);
        return new
        {
            games = result,
        };
    }

    private static Regex numberRegex { get; } = new("([0-9]+)");
    
    [HttpGet("games/multiget-playability-status")]
    public dynamic MultiGetPlayabilityStatus()
    {
        var ids = HttpContext.Request.QueryString.Value;
        return numberRegex.Matches(ids).Select(c => long.Parse(c.Value)).Distinct().Select(c => new
        {
            playabilityStatus = "Playable",
            isPlayable = true,
            universeId = c,
        });
    }

    [HttpGet("games/{universeId:long}/social-links/list")]
    public dynamic GetSocialLinks()
    {
        return new
        {
            data = new List<int>(),
        };
    }

    [HttpGet("games/recommendations/game/{universeId:long}")]
    public async Task<dynamic> GetRecommendedGames(long universeId, int maxRows = 6)
    {
        if (maxRows is > 100 or < 1) maxRows = 10;
        // todo: actually add recommendeds
        var result = await services.games.GetGamesList(userSession.userId, "popular", maxRows, null, null);
        return new
        {
            games = result,
        };
    }

    [HttpGet("games/multiget-place-details")]
    public async Task<IEnumerable<PlaceEntry>> MultiGetPlaceDetails(string placeIds)
    {
        return await services.games.MultiGetPlaceDetails(placeIds.Split(",").Select(long.Parse));
    }

    [HttpGet("games/votes")]
    public async Task<dynamic> GetGameVotes(string universeIds)
    {
        var ids = universeIds.Split(",").Select(long.Parse).Distinct().ToList();
        if (ids.Count is < 1 or > 100)
            throw new RobloxException(400, 0, "BadRequest");
        var uni = await services.games.MultiGetUniverseInfo(ids);

        var result = new List<dynamic>();
        foreach (var item in uni)
        {
            var votes = await services.assets.GetVoteForAsset(item.rootPlaceId);
            result.Add(new
            {
                id = item.id,
                upVotes = votes.upVotes,
                downVotes = votes.downVotes,
            });
        }

        return new
        {
            data = result,
        };
    }

    [HttpPost("games/{universeId:long}/icon")]
    public async Task SetGameIcon(long universeId, [Required, FromForm] IFormFile file)
    {
        FeatureFlags.FeatureCheck(FeatureFlag.UploadContentEnabled);
        if (file.Length == 0 || file.Length > 10 * 1024 * 1024)
            throw new BadRequestException(0, "The image must be smaller than 10 MB.");

        var universe = await GetEditableUniverse(universeId);
        await using var stream = file.OpenReadStream();
        if (await services.assets.ValidateImage(stream) == null)
            throw new BadRequestException(0, "Upload a PNG or JPEG image.");

        stream.Position = 0;
        await services.assets.SetGameIconFromStream(universe.rootPlaceId, stream);
    }

    [HttpPost("games/{universeId:long}/media")]
    public async Task AddGameThumbnail(long universeId, [Required, FromForm] IFormFile file)
    {
        FeatureFlags.FeatureCheck(FeatureFlag.UploadContentEnabled);
        if (file.Length == 0 || file.Length > 10 * 1024 * 1024)
            throw new BadRequestException(0, "The image must be smaller than 10 MB.");

        var universe = await GetEditableUniverse(universeId);
        var imageCount = (await services.games.GetGameMedia(universe.rootPlaceId))
            .Count(media => media.assetType == Type.Image);
        if (imageCount >= 10)
            throw new BadRequestException(0, "A game can have up to 10 thumbnails.");

        await using var stream = file.OpenReadStream();
        var imageInfo = await services.assets.ValidateImage(stream);
        if (imageInfo == null)
            throw new BadRequestException(0, "Upload a PNG or JPEG image.");

        stream.Position = 0;
        var creatorType = universe.creatorType;
        var imageAsset = await services.assets.CreateAsset("Game Thumbnail", "Game thumbnail",
            safeUserSession.userId, creatorType, universe.creatorId, stream, Type.Image, Genre.All,
            ModerationStatus.AwaitingApproval);
        stream.Position = 0;
        await services.assets.InsertOrUpdateAssetVersionMetadataImage(imageAsset.assetVersionId,
            (int)stream.Length, imageInfo.width, imageInfo.height, imageInfo.imageFormat,
            await services.assets.GenerateImageHash(stream));
        await services.games.AddGameImageMedia(universe.rootPlaceId, imageAsset.assetId);
    }

    [HttpPatch("games/{universeId:long}/user-votes")]
    public async Task VoteOnUniverse(long universeId, [Required, FromBody] VoteRequest request)
    {
        var uni = (await services.games.MultiGetUniverseInfo(new[] {universeId})).FirstOrDefault();
        await services.assets.VoteOnAsset(uni.rootPlaceId, safeUserSession.userId, request.vote);
    }
}