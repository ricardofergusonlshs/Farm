part of harvest_place_app;

enum HpjPreferenceAudience {
  customer,
  farmer,
}

class UserExperiencePreferences {
  final String dietaryStyle;
  final String organicPreference;
  final String recommendationStyle;
  final bool showAgricultureNews;
  final bool showRecommendations;
  final bool showPromotions;
  final bool showMealIdeas;
  final bool showFarmStories;
  final String feedImageMode;
  final bool showFreshReels;
  final bool reelsAutoplay;
  final bool reelsMutedByDefault;
  final bool showFarmerReels;
  final bool showRecipeReels;
  final bool showNutritionReels;
  final bool showPromotionalReels;
  final bool pushOrderUpdates;
  final bool pushMessages;
  final bool pushPriceDrops;
  final bool pushPromotions;
  final bool pushAgricultureNews;
  final bool personalizationEnabled;
  final bool useLocationForRecommendations;
  final bool saveActivityHistory;
  final bool farmerShowMarketUpdates;
  final bool farmerShowBuyingRequests;
  final bool farmerShowTrainingOpportunities;
  final bool farmerShowAgricultureNews;
  final bool farmerShowFarmPhotos;
  final bool farmerPublicProfile;
  final bool farmerNotifyCropDemand;
  final bool farmerNotifyCollectionChanges;
  final bool farmerNotifyPaymentUpdates;

  const UserExperiencePreferences({
    this.dietaryStyle = 'balanced',
    this.organicPreference = 'no_preference',
    this.recommendationStyle = 'balanced',
    this.showAgricultureNews = true,
    this.showRecommendations = true,
    this.showPromotions = true,
    this.showMealIdeas = true,
    this.showFarmStories = true,
    this.feedImageMode = 'balanced',
    this.showFreshReels = true,
    this.reelsAutoplay = true,
    this.reelsMutedByDefault = true,
    this.showFarmerReels = true,
    this.showRecipeReels = true,
    this.showNutritionReels = true,
    this.showPromotionalReels = true,
    this.pushOrderUpdates = true,
    this.pushMessages = true,
    this.pushPriceDrops = true,
    this.pushPromotions = false,
    this.pushAgricultureNews = false,
    this.personalizationEnabled = true,
    this.useLocationForRecommendations = true,
    this.saveActivityHistory = true,
    this.farmerShowMarketUpdates = true,
    this.farmerShowBuyingRequests = true,
    this.farmerShowTrainingOpportunities = true,
    this.farmerShowAgricultureNews = true,
    this.farmerShowFarmPhotos = true,
    this.farmerPublicProfile = true,
    this.farmerNotifyCropDemand = true,
    this.farmerNotifyCollectionChanges = true,
    this.farmerNotifyPaymentUpdates = true,
  });

  static const defaults = UserExperiencePreferences();

  bool get showFeedImages => feedImageMode != 'data_saver';

  factory UserExperiencePreferences.fromSupabase(Map<String, dynamic> data) {
    bool boolValue(String key, bool fallback) {
      final value = data[key];
      if (value is bool) return value;
      return fallback;
    }

    String textValue(String key, String fallback) {
      final value = data[key]?.toString().trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    return UserExperiencePreferences(
      dietaryStyle: textValue('dietary_style', 'balanced'),
      organicPreference: textValue('organic_preference', 'no_preference'),
      recommendationStyle: textValue('recommendation_style', 'balanced'),
      showAgricultureNews: boolValue('show_agriculture_news', true),
      showRecommendations: boolValue('show_recommendations', true),
      showPromotions: boolValue('show_promotions', true),
      showMealIdeas: boolValue('show_meal_ideas', true),
      showFarmStories: boolValue('show_farm_stories', true),
      feedImageMode: textValue('feed_image_mode', 'balanced'),
      showFreshReels: boolValue('show_fresh_reels', true),
      reelsAutoplay: boolValue('reels_autoplay', true),
      reelsMutedByDefault: boolValue('reels_muted_by_default', true),
      showFarmerReels: boolValue('show_farmer_reels', true),
      showRecipeReels: boolValue('show_recipe_reels', true),
      showNutritionReels: boolValue('show_nutrition_reels', true),
      showPromotionalReels: boolValue('show_promotional_reels', true),
      pushOrderUpdates: boolValue('push_order_updates', true),
      pushMessages: boolValue('push_messages', true),
      pushPriceDrops: boolValue('push_price_drops', true),
      pushPromotions: boolValue('push_promotions', false),
      pushAgricultureNews: boolValue('push_agriculture_news', false),
      personalizationEnabled: boolValue('personalization_enabled', true),
      useLocationForRecommendations:
          boolValue('use_location_for_recommendations', true),
      saveActivityHistory: boolValue('save_activity_history', true),
      farmerShowMarketUpdates: boolValue('farmer_show_market_updates', true),
      farmerShowBuyingRequests:
          boolValue('farmer_show_buying_requests', true),
      farmerShowTrainingOpportunities:
          boolValue('farmer_show_training_opportunities', true),
      farmerShowAgricultureNews:
          boolValue('farmer_show_agriculture_news', true),
      farmerShowFarmPhotos: boolValue('farmer_show_farm_photos', true),
      farmerPublicProfile: boolValue('farmer_public_profile', true),
      farmerNotifyCropDemand: boolValue('farmer_notify_crop_demand', true),
      farmerNotifyCollectionChanges:
          boolValue('farmer_notify_collection_changes', true),
      farmerNotifyPaymentUpdates:
          boolValue('farmer_notify_payment_updates', true),
    );
  }

  Map<String, dynamic> toSupabase(String userId) {
    return {
      'user_id': userId,
      'dietary_style': dietaryStyle,
      'organic_preference': organicPreference,
      'recommendation_style': recommendationStyle,
      'show_agriculture_news': showAgricultureNews,
      'show_recommendations': showRecommendations,
      'show_promotions': showPromotions,
      'show_meal_ideas': showMealIdeas,
      'show_farm_stories': showFarmStories,
      'feed_image_mode': feedImageMode,
      'show_fresh_reels': showFreshReels,
      'reels_autoplay': reelsAutoplay,
      'reels_muted_by_default': reelsMutedByDefault,
      'show_farmer_reels': showFarmerReels,
      'show_recipe_reels': showRecipeReels,
      'show_nutrition_reels': showNutritionReels,
      'show_promotional_reels': showPromotionalReels,
      'push_order_updates': pushOrderUpdates,
      'push_messages': pushMessages,
      'push_price_drops': pushPriceDrops,
      'push_promotions': pushPromotions,
      'push_agriculture_news': pushAgricultureNews,
      'personalization_enabled': personalizationEnabled,
      'use_location_for_recommendations': useLocationForRecommendations,
      'save_activity_history': saveActivityHistory,
      'farmer_show_market_updates': farmerShowMarketUpdates,
      'farmer_show_buying_requests': farmerShowBuyingRequests,
      'farmer_show_training_opportunities': farmerShowTrainingOpportunities,
      'farmer_show_agriculture_news': farmerShowAgricultureNews,
      'farmer_show_farm_photos': farmerShowFarmPhotos,
      'farmer_public_profile': farmerPublicProfile,
      'farmer_notify_crop_demand': farmerNotifyCropDemand,
      'farmer_notify_collection_changes': farmerNotifyCollectionChanges,
      'farmer_notify_payment_updates': farmerNotifyPaymentUpdates,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserExperiencePreferences copyWith({
    String? dietaryStyle,
    String? organicPreference,
    String? recommendationStyle,
    bool? showAgricultureNews,
    bool? showRecommendations,
    bool? showPromotions,
    bool? showMealIdeas,
    bool? showFarmStories,
    String? feedImageMode,
    bool? showFreshReels,
    bool? reelsAutoplay,
    bool? reelsMutedByDefault,
    bool? showFarmerReels,
    bool? showRecipeReels,
    bool? showNutritionReels,
    bool? showPromotionalReels,
    bool? pushOrderUpdates,
    bool? pushMessages,
    bool? pushPriceDrops,
    bool? pushPromotions,
    bool? pushAgricultureNews,
    bool? personalizationEnabled,
    bool? useLocationForRecommendations,
    bool? saveActivityHistory,
    bool? farmerShowMarketUpdates,
    bool? farmerShowBuyingRequests,
    bool? farmerShowTrainingOpportunities,
    bool? farmerShowAgricultureNews,
    bool? farmerShowFarmPhotos,
    bool? farmerPublicProfile,
    bool? farmerNotifyCropDemand,
    bool? farmerNotifyCollectionChanges,
    bool? farmerNotifyPaymentUpdates,
  }) {
    return UserExperiencePreferences(
      dietaryStyle: dietaryStyle ?? this.dietaryStyle,
      organicPreference: organicPreference ?? this.organicPreference,
      recommendationStyle: recommendationStyle ?? this.recommendationStyle,
      showAgricultureNews: showAgricultureNews ?? this.showAgricultureNews,
      showRecommendations: showRecommendations ?? this.showRecommendations,
      showPromotions: showPromotions ?? this.showPromotions,
      showMealIdeas: showMealIdeas ?? this.showMealIdeas,
      showFarmStories: showFarmStories ?? this.showFarmStories,
      feedImageMode: feedImageMode ?? this.feedImageMode,
      showFreshReels: showFreshReels ?? this.showFreshReels,
      reelsAutoplay: reelsAutoplay ?? this.reelsAutoplay,
      reelsMutedByDefault:
          reelsMutedByDefault ?? this.reelsMutedByDefault,
      showFarmerReels: showFarmerReels ?? this.showFarmerReels,
      showRecipeReels: showRecipeReels ?? this.showRecipeReels,
      showNutritionReels: showNutritionReels ?? this.showNutritionReels,
      showPromotionalReels:
          showPromotionalReels ?? this.showPromotionalReels,
      pushOrderUpdates: pushOrderUpdates ?? this.pushOrderUpdates,
      pushMessages: pushMessages ?? this.pushMessages,
      pushPriceDrops: pushPriceDrops ?? this.pushPriceDrops,
      pushPromotions: pushPromotions ?? this.pushPromotions,
      pushAgricultureNews:
          pushAgricultureNews ?? this.pushAgricultureNews,
      personalizationEnabled:
          personalizationEnabled ?? this.personalizationEnabled,
      useLocationForRecommendations: useLocationForRecommendations ??
          this.useLocationForRecommendations,
      saveActivityHistory: saveActivityHistory ?? this.saveActivityHistory,
      farmerShowMarketUpdates:
          farmerShowMarketUpdates ?? this.farmerShowMarketUpdates,
      farmerShowBuyingRequests:
          farmerShowBuyingRequests ?? this.farmerShowBuyingRequests,
      farmerShowTrainingOpportunities: farmerShowTrainingOpportunities ??
          this.farmerShowTrainingOpportunities,
      farmerShowAgricultureNews:
          farmerShowAgricultureNews ?? this.farmerShowAgricultureNews,
      farmerShowFarmPhotos:
          farmerShowFarmPhotos ?? this.farmerShowFarmPhotos,
      farmerPublicProfile: farmerPublicProfile ?? this.farmerPublicProfile,
      farmerNotifyCropDemand:
          farmerNotifyCropDemand ?? this.farmerNotifyCropDemand,
      farmerNotifyCollectionChanges: farmerNotifyCollectionChanges ??
          this.farmerNotifyCollectionChanges,
      farmerNotifyPaymentUpdates:
          farmerNotifyPaymentUpdates ?? this.farmerNotifyPaymentUpdates,
    );
  }
}

UserExperiencePreferences hpjCurrentUserExperiencePreferences =
    UserExperiencePreferences.defaults;

Future<UserExperiencePreferences> fetchCurrentUserExperiencePreferences() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    hpjCurrentUserExperiencePreferences = UserExperiencePreferences.defaults;
    return hpjCurrentUserExperiencePreferences;
  }

  try {
    final response = await supabase
        .from('user_experience_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      hpjCurrentUserExperiencePreferences = UserExperiencePreferences.defaults;
      return hpjCurrentUserExperiencePreferences;
    }

    hpjCurrentUserExperiencePreferences = UserExperiencePreferences.fromSupabase(
      Map<String, dynamic>.from(response),
    );
    return hpjCurrentUserExperiencePreferences;
  } catch (error) {
    farmDebugLog('User preferences unavailable: $error');
    return hpjCurrentUserExperiencePreferences;
  }
}

Future<void> saveCurrentUserExperiencePreferences(
  UserExperiencePreferences preferences,
) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Please sign in to save preferences.');

  await supabase.from('user_experience_preferences').upsert(
        preferences.toSupabase(user.id),
        onConflict: 'user_id',
      );
  hpjCurrentUserExperiencePreferences = preferences;
}

class HpjSettingsPreferencesScreen extends StatefulWidget {
  final HpjPreferenceAudience audience;

  const HpjSettingsPreferencesScreen({
    super.key,
    required this.audience,
  });

  @override
  State<HpjSettingsPreferencesScreen> createState() =>
      _HpjSettingsPreferencesScreenState();
}

class _HpjSettingsPreferencesScreenState
    extends State<HpjSettingsPreferencesScreen> {
  late Future<UserExperiencePreferences> _future;
  UserExperiencePreferences _preferences = UserExperiencePreferences.defaults;
  bool _loaded = false;
  bool _saving = false;

  bool get _isFarmer => widget.audience == HpjPreferenceAudience.farmer;

  @override
  void initState() {
    super.initState();
    _future = fetchCurrentUserExperiencePreferences();
  }

  void _update(UserExperiencePreferences next) {
    setState(() => _preferences = next);
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await saveCurrentUserExperiencePreferences(_preferences);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UpdatePasswordScreen(
          onPasswordUpdated: () {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<UserExperiencePreferences>(
        future: _future,
        builder: (context, snapshot) {
          if (!_loaded && snapshot.hasData) {
            _preferences = snapshot.data!;
            _loaded = true;
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !_loaded) {
            return const SizedBox.expand(child: SkeletonList(count: 4));
          }

          if (snapshot.hasError && !_loaded) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(_isFarmer ? 'Back to Farmer Account' : 'Back to Account'),
                  ),
                ),
                const Header(
                  title: 'Settings & Preferences',
                  subtitle: 'Your HPJ experience',
                ),
                const SizedBox(height: 16),
                FarmEmptyState(
                  icon: Icons.settings_outlined,
                  title: 'Could not load settings',
                  message: friendlyAppError(snapshot.error!),
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(_isFarmer ? 'Back to Farmer Account' : 'Back to Account'),
                ),
              ),
              const SizedBox(height: 4),
              Header(
                title: 'Settings & Preferences',
                subtitle: _isFarmer
                    ? 'Control your farmer feed, alerts and privacy.'
                    : 'Make HPJ fit the way you shop and browse.',
              ),
              const SizedBox(height: 14),
              _SettingsIntroCard(isFarmer: _isFarmer),
              const SizedBox(height: 12),
              if (!_isFarmer) ...[
                _SettingsSection(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Food & Shopping',
                  subtitle:
                      'These choices guide recommendations and future meal planning.',
                  children: [
                    _SettingsDropdown(
                      title: 'Dietary preference',
                      subtitle: 'Choose the style that best fits you.',
                      value: _preferences.dietaryStyle,
                      options: const {
                        'balanced': 'No dietary preference',
                        'vegan': 'Vegan',
                        'vegetarian': 'Vegetarian',
                      },
                      onChanged: (value) => _update(
                        _preferences.copyWith(dietaryStyle: value),
                      ),
                    ),
                    _SettingsDropdown(
                      title: 'Organic preference',
                      subtitle:
                          'Prefer organic without hiding useful alternatives unless you choose organic only.',
                      value: _preferences.organicPreference,
                      options: const {
                        'no_preference': 'No preference',
                        'prefer': 'Prefer organic',
                        'only': 'Organic only',
                      },
                      onChanged: (value) => _update(
                        _preferences.copyWith(organicPreference: value),
                      ),
                    ),
                    _SettingsDropdown(
                      title: 'Recommendation style',
                      subtitle: 'Choose what HPJ should prioritize first.',
                      value: _preferences.recommendationStyle,
                      options: const {
                        'balanced': 'Balanced',
                        'favorites': 'My favourites',
                        'healthy_variety': 'Healthy variety',
                        'budget_first': 'Budget first',
                        'organic_first': 'Organic first',
                        'vegan': 'Vegan first',
                      },
                      onChanged: (value) => _update(
                        _preferences.copyWith(recommendationStyle: value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  icon: Icons.dynamic_feed_outlined,
                  title: 'Feed & Content',
                  subtitle: 'Choose what appears in your HPJ experience.',
                  children: [
                    _SettingsSwitch(
                      title: 'Agriculture updates',
                      subtitle: 'Jamaican agriculture news and HPJ updates.',
                      value: _preferences.showAgricultureNews,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showAgricultureNews: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Recommended for you',
                      subtitle: 'Personalized product suggestions.',
                      value: _preferences.showRecommendations,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showRecommendations: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Deals & promotions',
                      subtitle: 'Promotional content and sponsored offers.',
                      value: _preferences.showPromotions,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showPromotions: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Meal ideas',
                      subtitle: 'Recipes and What’s Cooking content.',
                      value: _preferences.showMealIdeas,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showMealIdeas: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Farm stories',
                      subtitle: 'Farmer and farm-origin stories.',
                      value: _preferences.showFarmStories,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showFarmStories: value),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _SettingsSection(
                  icon: Icons.dynamic_feed_outlined,
                  title: 'Farmer Feed',
                  subtitle:
                      'Keep operational alerts on while choosing the optional content you want to see.',
                  children: [
                    _SettingsSwitch(
                      title: 'HPJ buying requests',
                      subtitle: 'Buyer demand and produce opportunities.',
                      value: _preferences.farmerShowBuyingRequests,
                      onChanged: (value) => _update(
                        _preferences.copyWith(
                          farmerShowBuyingRequests: value,
                        ),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Market updates',
                      subtitle: 'Supply-demand and market intelligence.',
                      value: _preferences.farmerShowMarketUpdates,
                      onChanged: (value) => _update(
                        _preferences.copyWith(farmerShowMarketUpdates: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Agriculture news',
                      subtitle: 'Official notices, news and opportunities.',
                      value: _preferences.farmerShowAgricultureNews,
                      onChanged: (value) => _update(
                        _preferences.copyWith(farmerShowAgricultureNews: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Training opportunities',
                      subtitle: 'Training, workshops and farmer education.',
                      value: _preferences.farmerShowTrainingOpportunities,
                      onChanged: (value) => _update(
                        _preferences.copyWith(
                          farmerShowTrainingOpportunities: value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  icon: Icons.storefront_outlined,
                  title: 'Farm Visibility',
                  subtitle:
                      'Control how your farm can appear in customer-facing content.',
                  children: [
                    _SettingsSwitch(
                      title: 'Public farm profile',
                      subtitle:
                          'Allow approved farm details to appear to customers.',
                      value: _preferences.farmerPublicProfile,
                      onChanged: (value) => _update(
                        _preferences.copyWith(farmerPublicProfile: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Show farm photos',
                      subtitle:
                          'Allow approved farm photos in customer-facing stories and product content.',
                      value: _preferences.farmerShowFarmPhotos,
                      onChanged: (value) => _update(
                        _preferences.copyWith(farmerShowFarmPhotos: value),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.image_outlined,
                title: 'Images & Data',
                subtitle: 'Choose how media-heavy your feed should be.',
                children: [
                  _SettingsDropdown(
                    title: 'Feed image mode',
                    subtitle:
                        'Data Saver hides optional feed images to reduce mobile data usage.',
                    value: _preferences.feedImageMode,
                    options: const {
                      'rich': 'Rich images',
                      'balanced': 'Balanced',
                      'data_saver': 'Data Saver',
                    },
                    onChanged: (value) => _update(
                      _preferences.copyWith(feedImageMode: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.play_circle_outline_rounded,
                title: 'Video & Fresh Reels',
                subtitle: _isFarmer
                    ? 'Control Fresh Reels in your farmer feed and viewer.'
                    : 'Choose how Fresh Reels appear in your feed and viewer.',
                children: [
                  _SettingsSwitch(
                    title: 'Show Fresh Reels',
                    subtitle: 'Show approved short videos in your feed and Fresh Reels viewer.',
                    value: _preferences.showFreshReels,
                    onChanged: (value) => _update(
                      _preferences.copyWith(showFreshReels: value),
                    ),
                  ),
                  _SettingsSwitch(
                    title: 'Autoplay reels',
                    subtitle:
                        'Start the active reel automatically. Data Saver always pauses autoplay.',
                    value: _preferences.reelsAutoplay,
                    onChanged: (value) => _update(
                      _preferences.copyWith(reelsAutoplay: value),
                    ),
                  ),
                  _SettingsSwitch(
                    title: 'Mute by default',
                    subtitle: 'Start reels quietly and tap sound when you want it.',
                    value: _preferences.reelsMutedByDefault,
                    onChanged: (value) => _update(
                      _preferences.copyWith(reelsMutedByDefault: value),
                    ),
                  ),
                  if (!_isFarmer) ...[
                    _SettingsSwitch(
                      title: 'Farmer & harvest reels',
                      subtitle: 'Farm updates, harvesting and new arrivals.',
                      value: _preferences.showFarmerReels,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showFarmerReels: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Recipe reels',
                      subtitle: 'Short preparation and Jamaican meal ideas.',
                      value: _preferences.showRecipeReels,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showRecipeReels: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Nutrition reels',
                      subtitle: 'Produce and nutrition education from HPJ.',
                      value: _preferences.showNutritionReels,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showNutritionReels: value),
                      ),
                    ),
                    _SettingsSwitch(
                      title: 'Promotional reels',
                      subtitle: 'HPJ offers and clearly labelled future sponsored videos.',
                      value: _preferences.showPromotionalReels,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showPromotionalReels: value),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                subtitle: _isFarmer
                    ? 'Critical accepted-order, collection and account notices may still be shown when required.'
                    : 'Critical order and security notices remain available when required.',
                children: _isFarmer
                    ? [
                        _SettingsSwitch(
                          title: 'Crop demand alerts',
                          subtitle: 'Tell me when HPJ needs crops I supply.',
                          value: _preferences.farmerNotifyCropDemand,
                          onChanged: (value) => _update(
                            _preferences.copyWith(
                              farmerNotifyCropDemand: value,
                            ),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Collection changes',
                          subtitle: 'Pickup schedule changes and reminders.',
                          value: _preferences.farmerNotifyCollectionChanges,
                          onChanged: (value) => _update(
                            _preferences.copyWith(
                              farmerNotifyCollectionChanges: value,
                            ),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Payment updates',
                          subtitle: 'Settlement and payout updates.',
                          value: _preferences.farmerNotifyPaymentUpdates,
                          onChanged: (value) => _update(
                            _preferences.copyWith(
                              farmerNotifyPaymentUpdates: value,
                            ),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Messages',
                          subtitle: 'New messages from HPJ.',
                          value: _preferences.pushMessages,
                          onChanged: (value) => _update(
                            _preferences.copyWith(pushMessages: value),
                          ),
                        ),
                      ]
                    : [
                        _SettingsSwitch(
                          title: 'Order & delivery updates',
                          subtitle: 'Order status and delivery progress.',
                          value: _preferences.pushOrderUpdates,
                          onChanged: (value) => _update(
                            _preferences.copyWith(pushOrderUpdates: value),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Messages',
                          subtitle: 'Chat and support replies.',
                          value: _preferences.pushMessages,
                          onChanged: (value) => _update(
                            _preferences.copyWith(pushMessages: value),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Price drops & restocks',
                          subtitle: 'Useful shopping alerts.',
                          value: _preferences.pushPriceDrops,
                          onChanged: (value) => _update(
                            _preferences.copyWith(pushPriceDrops: value),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Promotions',
                          subtitle: 'Special offers and campaign alerts.',
                          value: _preferences.pushPromotions,
                          onChanged: (value) => _update(
                            _preferences.copyWith(pushPromotions: value),
                          ),
                        ),
                        _SettingsSwitch(
                          title: 'Agriculture news',
                          subtitle: 'Important agriculture updates.',
                          value: _preferences.pushAgricultureNews,
                          onChanged: (value) => _update(
                            _preferences.copyWith(pushAgricultureNews: value),
                          ),
                        ),
                      ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy & Personalization',
                subtitle: 'Control how HPJ tailors your experience.',
                children: [
                  _SettingsSwitch(
                    title: 'Personalized experience',
                    subtitle:
                        'Use your HPJ activity to improve recommendations and feed relevance.',
                    value: _preferences.personalizationEnabled,
                    onChanged: (value) => _update(
                      _preferences.copyWith(personalizationEnabled: value),
                    ),
                  ),
                  _SettingsSwitch(
                    title: 'Use location for relevance',
                    subtitle:
                        'Use your saved area to improve local availability and recommendations.',
                    value: _preferences.useLocationForRecommendations,
                    onChanged: (value) => _update(
                      _preferences.copyWith(
                        useLocationForRecommendations: value,
                      ),
                    ),
                  ),
                  _SettingsSwitch(
                    title: 'Save activity history',
                    subtitle:
                        'Use recent activity such as viewed items to improve your experience.',
                    value: _preferences.saveActivityHistory,
                    onChanged: (value) => _update(
                      _preferences.copyWith(saveActivityHistory: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                icon: Icons.lock_outline_rounded,
                title: 'Account & Security',
                subtitle: 'Security controls for your HPJ account.',
                children: [
                  _SettingsActionTile(
                    icon: Icons.password_rounded,
                    title: 'Change password',
                    subtitle: 'Create a new password for this account.',
                    onTap: _openPassword,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Settings'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsIntroCard extends StatelessWidget {
  final bool isFarmer;

  const _SettingsIntroCard({required this.isFarmer});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isFarmer ? Icons.agriculture_outlined : Icons.tune_rounded,
              color: FarmColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFarmer ? 'Your farmer experience' : 'Your HPJ experience',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFarmer
                      ? 'Optional feed content can be reduced without hiding important collection, payment or accepted-request information.'
                      : 'Choose what matters to you without crowding the Home or Shop screens.',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.8,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: FarmColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.8,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: const TextStyle(
          color: FarmColors.ink,
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontSize: 9.4,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      value: value,
      activeColor: FarmColors.primary,
      onChanged: onChanged,
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _SettingsDropdown({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = options.containsKey(value) ? value : options.keys.first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.4,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: safeValue,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: options.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: FarmColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: FarmColors.primary, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: FarmColors.ink,
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: FarmColors.mutedText,
          fontSize: 9.4,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
