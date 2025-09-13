defmodule WebMediaSeeder do
  @moduledoc """
  Creates posts with real sports media from web URLs
  """

  @sports_images %{
    "football" => [
      "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800",
      "https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800",
      "https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=800",
      "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800",
      "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800"
    ],
    "basketball" => [
      "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800",
      "https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?w=800",
      "https://images.unsplash.com/photo-1519861531473-9200262188bf?w=800",
      "https://images.unsplash.com/photo-1574623452334-1e0ac2b3ccb4?w=800",
      "https://images.unsplash.com/photo-1579952363873-27d3bfad9c0d?w=800"
    ],
    "tennis" => [
      "https://images.unsplash.com/photo-1544717684-d03fcaeb2b3a?w=800",
      "https://images.unsplash.com/photo-1530915365347-e35b749f0381?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800",
      "https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=800",
      "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800"
    ],
    "baseball" => [
      "https://images.unsplash.com/photo-1566577739112-5180d4bf9390?w=800",
      "https://images.unsplash.com/photo-1614469723922-c043ad9fd036?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800",
      "https://images.unsplash.com/photo-1566577134770-3d85bb3a9cc4?w=800",
      "https://images.unsplash.com/photo-1508296695146-257a814070b4?w=800"
    ],
    "hockey" => [
      "https://images.unsplash.com/photo-1515703407324-5f753afd8be8?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800",
      "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800",
      "https://images.unsplash.com/photo-1578928996699-3108b3781cf8?w=800",
      "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800"
    ],
    "swimming" => [
      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800",
      "https://images.unsplash.com/photo-1591154669695-5f2a8d20c089?w=800",
      "https://images.unsplash.com/photo-1560089000-7433a4ebbd64?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ],
    "athletics" => [
      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800",
      "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800",
      "https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ]
  }

  @sports_videos %{
    "football" => [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    ],
    "basketball" => [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
    ],
    "tennis" => [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_640x360_1mb.mp4",
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    ],
    "baseball" => [
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
    ],
    "hockey" => [
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
    ],
    "swimming" => [
      "https://sample-videos.com/zip/10/mp4/SampleVideo_720x480_1mb.mp4"
    ],
    "athletics" => [
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
    ]
  }

  @doc """
  Creates media records for a given post with real web URLs
  """

  def create_media_records_for_post(post, sport_slug) do
    available_images = Map.fetch!(@sports_images, sport_slug)
    available_videos = Map.fetch!(@sports_videos, sport_slug)

    media_items =
      Enum.map(available_images, &{:image, &1}) ++
      Enum.map(available_videos, &{:video, &1})

    Enum.with_index(media_items, 1)
    |> Enum.map(fn
      {{:image, url}, position} ->
        create_image_media(post, sport_slug, position, url)

      {{:video, url}, position} ->
        create_video_media(post, sport_slug, position, url)
    end)
  end

  @doc """
  Generates sport-specific caption
  """
  def get_sport_caption(sport_name, city_name) do
    captions = [
      "Amazing #{sport_name} session in #{city_name}! 💪",
      "Training hard for the next #{sport_name} competition 🏆",
      "Beautiful day for #{sport_name} in #{city_name} ☀️",
      "#{sport_name} season is here! Who's ready? 🔥",
      "Nothing beats #{sport_name} with this view in #{city_name}! 📸",
      "#{sport_name} training complete ✅ Feeling strong!",
      "#{city_name} has the best #{sport_name} facilities! 🏟️",
      "Game day vibes in #{city_name}! Let's go! ⚡",
      "#{sport_name} life in #{city_name} is unmatched 🌟",
      "Post-workout glow after intense #{sport_name} session 💯"
    ]

    Enum.random(captions)
  end

  defp create_image_media(post, sport_slug, position, url) do
    SportsnetApi.Repo.insert!(%SportsnetApi.Social.Media{
      url: url,
      media_type: "image",
      position: position,
      file_size: Enum.random(50_000..2_000_000),
      filename: "sports_#{sport_slug}_#{post.id}_#{position}.jpg",
      width: 800,
      height: 600,
      duration: nil,
      post: post
    })
  end

  defp create_video_media(post, sport_slug, position, url) do
    SportsnetApi.Repo.insert!(%SportsnetApi.Social.Media{
      url: url,
      media_type: "video",
      position: position,
      file_size: Enum.random(1_000_000..10_000_000),
      filename: "sports_#{sport_slug}_#{post.id}_video_#{position}.mp4",
      width: 1280,
      height: 720,
      duration: Enum.random(10..300),
      post: post
    })
  end
end
