# Domain Model — Sync Lifestyle Automation Platform

> Trích xuất toàn bộ entities và enums từ tất cả services.  
> Storage: **PostgreSQL** (IAM, Payment, Order) · **MongoDB** (Exercise, Roadmap, Notification, Social, Marketplace, Nutrition) · **Redis** (Order — cart/tracking cache, không phải domain entity) · **Go** (Biometric)

---

## Libs.Shared

### Base Entity

**`BaseAuditableEntity`** — dùng cho các service PostgreSQL

| Property | Type |
|----------|------|
| Id | Guid |
| CreatedAt | DateTimeOffset |
| UpdatedAt | DateTimeOffset? |
| DeletedAt | DateTimeOffset? |

**`BaseMongoEntity`** — mỗi service MongoDB có bản kế thừa riêng (Exercise, Roadmap, Notification, Social, Marketplace, Nutrition)

| Property | Type |
|----------|------|
| Id | Guid |
| CreatedAt | DateTimeOffset |
| UpdatedAt | DateTimeOffset? |

### Value Objects (Shared)

**`NutritionSnapshot`** — embedded trong Marketplace (`FoodMenuItem`, `AffiliateProduct`)

| Property | Type |
|----------|------|
| Calories | int |
| ProteinGram | decimal |
| CarbGram | decimal |
| FatGram | decimal |
| ServingDescription | string? |

### Enums (Shared — dùng chung)

| Enum | Values |
|------|--------|
| **AssetType** | Unity3D=0, Video=1, Image=2 |
| **BodyRegion** | UpperBody=0, LowerBody=1, FullBody=2, Core=3 |
| **Difficulty** | Beginner=0, Intermediate=1, Advanced=2 |
| **ExerciseCategory** | Strength=0, Cardio=1, Flexibility=2, Mobility=3 |
| **MovementPattern** | HorizontalPush=0, HorizontalPull=1, VerticalPush=2, VerticalPull=3, Squat=4, Hinge=5, Core=6 |
| **RoadmapStatus** | Active=0, Paused=1, Completed=2, Abandoned=3 |
| **SessionStatus** | Scheduled=0, Completed=1, Skipped=2, InProgress=3 |
| **Visibility** | Public=0, Private=1 |
| **MealType** | Breakfast=0, Lunch=1, Dinner=2, Snack=3, PreWorkout=4, PostWorkout=5 |
| **FoodCategory** | Grains=0, Protein=1, Vegetable=2, Fruit=3, Dairy=4, Fat=5, Beverage=6, Snack=7, PreparedMeal=8, Supplement=9, FastFood=10 |
| **DietaryTag** | Vegetarian=0, Vegan=1, Keto=2, LowCarb=3, HighProtein=4, LowFat=5, GlutenFree=6, Halal=7, DairyFree=8 |

---

## Service: IAM

> PostgreSQL (schema `iam`) · `BaseAuditableEntity`

### Entities

**`User`**

| Property | Type |
|----------|------|
| Email | string |
| PhoneNumber | string? |
| PasswordHash | string |
| FullName | string |
| AvatarUrl | string? |
| BackgroundImageUrl | string? |
| Role | UserRole |
| Status | UserStatus |
| SubscriptionTier | SubscriptionTier |
| EmailVerified | bool |
| EmailVerificationToken | string? |
| PasswordResetToken | string? |
| PasswordResetTokenExpiresAt | DateTimeOffset? |
| PhoneVerified | bool |
| PreferredLanguage | string |
| TimeZone | string |
| LastLoginAt | DateTimeOffset? |
| LastActiveAt | DateTimeOffset? |
| BiometricProfile | BiometricProfile? |
| UserPreference | UserPreference? |
| AIContextProfile | AIContextProfile? |
| GamificationProfile | GamificationProfile? |
| Devices | ICollection\<UserDevice\> |
| Assets | ICollection\<UserAsset\> |
| Achievements | ICollection\<UserAchievement\> |
| Vouchers | ICollection\<UserVoucher\> |

**`BiometricProfile`**

| Property | Type |
|----------|------|
| UserId | Guid |
| Gender | Gender |
| DateOfBirth | DateOnly |
| HeightCm | decimal |
| CurrentWeightKg | decimal |
| TargetWeightKg | decimal |
| CurrentBodyFatPercentage | decimal? |
| GoalBodyFatPercentage | decimal? |
| MuscleMassKg | decimal? |
| FitnessGoal | FitnessGoal |
| ActivityLevel | ActivityLevel |
| FitnessExperienceLevel | FitnessExperienceLevel |
| WorkoutLocationPreference | WorkoutLocationPreference |
| BaseTDEE | int |
| BMR | int |
| DailyProteinTargetGram | int? |
| DailyCarbTargetGram | int? |
| DailyFatTargetGram | int? |
| Injuries | List\<string\>? |
| Medications | List\<string\>? |

**`UserPreference`**

| Property | Type |
|----------|------|
| UserId | Guid |
| Allergies | List\<AllergyItem\>? |
| FavoriteFoods | List\<string\>? |
| DislikedFoods | List\<string\>? |
| AgentPersona | AgentPersona |
| MotivationStyle | MotivationStyle |
| AutoOrderEnabled | bool |
| MaxAutoOrderLimitDaily | decimal? |
| MaxAutoOrderLimitPerOrder | decimal? |
| DataSharingConsent | bool |
| MarketingConsent | bool |
| SmartPushEnabled | bool |
| AllowAiGeneratedNotification | bool |
| PreferredReminderTime | TimeSpan? |

**`AIContextProfile`**

| Property | Type |
|----------|------|
| UserId | Guid |
| AdherenceScore | decimal |
| BurnoutRiskScore | decimal |
| ChurnRiskScore | decimal |
| MotivationScore | decimal |
| RecoveryScore | decimal |
| NutritionComplianceScore | decimal |
| WorkoutComplianceScore | decimal |
| PeakEnergyTimeWindow | string? |
| PreferredInterventionStyle | string? |
| LastBurnoutDetectedAt | DateTimeOffset? |
| LastWorkoutSkippedAt | DateTimeOffset? |
| LastCheatMealAt | DateTimeOffset? |
| CurrentMood | string? |
| AIConfidenceScore | decimal |
| LastReplanAt | DateTimeOffset? |

**`GamificationProfile`**

| Property | Type |
|----------|------|
| UserId | Guid |
| CurrentLevel | int |
| CurrentXP | long |
| CurrentStreak | int |
| LongestStreak | int |
| SyncCoins | decimal |
| AchievementPoints | long |
| ConsecutivePerfectDays | int |
| LastActivityDate | DateTimeOffset? |

**`Achievement`**

| Property | Type |
|----------|------|
| Code | string |
| Name | string |
| Description | string |
| XPReward | int |
| CoinReward | int |
| IconUrl | string |
| RequirementJson | string? |

**`UserAchievement`**

| Property | Type |
|----------|------|
| UserId | Guid |
| AchievementId | Guid |
| UnlockedAt | DateTimeOffset |

**`UserAsset`**

| Property | Type |
|----------|------|
| UserId | Guid |
| UnityAssetId | string |
| AssetCategory | string |
| Rarity | string |
| SourceType | string |
| IsEquipped | bool |
| EquippedAt | DateTimeOffset? |
| UnlockedAt | DateTimeOffset |
| ExpiredAt | DateTimeOffset? |
| Metadata | string? |

**`UserDevice`**

| Property | Type |
|----------|------|
| UserId | Guid |
| DeviceId | string |
| Platform | DevicePlatform |
| PushToken | string? |
| AppVersion | string |
| LastSeenAt | DateTimeOffset? |
| RefreshTokenHash | string? |
| RefreshTokenExpiryTime | DateTimeOffset? |
| IsRevoked | bool |

**`UserVoucher`** _(IAM — inventory voucher, khác Payment.UserVoucher)_

| Property | Type |
|----------|------|
| UserId | Guid |
| PromotionCampaignId | Guid? |
| VoucherCode | string |
| Name | string |
| PromotionType | string |
| Value | decimal |
| Status | VoucherStatus |
| AcquiredAt | DateTimeOffset |
| UsedAt | DateTimeOffset? |
| ValidUntil | DateTimeOffset? |

### Value Objects

**`AllergyItem`** _(record, lưu JSONB trong `UserPreference`)_

| Property | Type |
|----------|------|
| AllergenName | string |
| Severity | string? |
| Notes | string? |

### Enums

| Enum | Values |
|------|--------|
| **UserRole** | User=0, Partner=1, SystemAdmin=2 |
| **UserStatus** | Onboarding=0, Active=1, Suspended=2, PendingVerification=3, Deleted=4 |
| **SubscriptionTier** | Free=0, Premium=1, Ultra=2 |
| **Gender** | Male=0, Female=1, Other=2, PreferNotToSay=3 |
| **FitnessGoal** | LoseFat=0, BuildMuscle=1, Maintain=2, Recomposition=3, ImproveEndurance=4, GeneralHealth=5 |
| **ActivityLevel** | Sedentary=0, LightlyActive=1, ModeratelyActive=2, VeryActive=3, Athlete=4 |
| **FitnessExperienceLevel** | Beginner=0, Intermediate=1, Advanced=2 |
| **WorkoutLocationPreference** | Home=0, Gym=1, Outdoor=2, Hybrid=3 |
| **DevicePlatform** | IOS=0, Android=1, Web=2 |
| **VoucherStatus** | Available=0, Used=1, Expired=2, Revoked=3 |
| **AgentPersona** | StrictCoach=0, FriendlyBuddy=1, CalmMentor=2, EnergeticTrainer=3 |
| **MotivationStyle** | Supportive=0, Aggressive=1, DisciplineFocused=2, Friendly=3, Competitive=4, Minimal=5 |

---

## Service: Payment

> PostgreSQL (schema `payment`) · `BaseAuditableEntity`

### Entities

**`Wallet`**

| Property | Type |
|----------|------|
| UserId | Guid |
| AvailableBalance | decimal |
| LockedBalance | decimal |
| RewardCoinBalance | decimal |
| Currency | string |
| AutoPaymentEnabled | bool |
| DailyAutoSpendingLimit | decimal |
| MonthlyAutoSpendingLimit | decimal |
| RemainingDailyAutoLimit | decimal |
| RemainingMonthlyAutoLimit | decimal |
| LastResetDailyLimitAt | DateTimeOffset |
| LastResetMonthlyLimitAt | DateTimeOffset |
| RiskScore | decimal |

**`Transaction`**

| Property | Type |
|----------|------|
| WalletId | Guid? |
| UserId | Guid |
| TransactionType | TransactionType |
| Status | TransactionStatus |
| PaymentMethod | PaymentMethod |
| Amount | decimal |
| Currency | string |
| ExternalReferenceId | string? |
| OrderCode | long |
| Provider | PaymentProvider |
| RawProviderPayload | string? |
| RelatedEntityType | string? |
| RelatedEntityId | Guid? |
| Description | string? |
| IsAiInitiated | bool |
| AIReasoningSnapshotJson | string? |
| SpendingAuthorizationType | SpendingAuthorizationType |
| ProcessedAt | DateTimeOffset? |
| FailedReason | string? |
| CouponCode | string? |

**`WalletLedger`**

| Property | Type |
|----------|------|
| WalletId | Guid? |
| TransactionId | Guid |
| EntryType | WalletTransactionType |
| Amount | decimal |
| BalanceBefore | decimal |
| BalanceAfter | decimal |
| MetadataJson | string? |

**`SubscriptionPlan`**

| Property | Type |
|----------|------|
| Name | string |
| Description | string? |
| MonthlyPrice | decimal |
| YearlyPrice | decimal |
| Currency | string |
| FeaturesJson | string? |
| AiUsageLimitPerMonth | int |
| PremiumWorkoutAccess | bool |
| PremiumMarketplaceAccess | bool |
| PriorityAiResponses | bool |
| MaxAiAutoOrdersPerMonth | int |
| IsActive | bool |
| GooglePlayProductId | string? |

**`UserSubscription`**

| Property | Type |
|----------|------|
| UserId | Guid |
| SubscriptionPlanId | Guid |
| Status | SubscriptionStatus |
| StartedAt | DateTimeOffset |
| ExpiredAt | DateTimeOffset? |
| AutoRenew | bool |
| LastBillingAt | DateTimeOffset? |
| NextBillingAt | DateTimeOffset? |
| CancellationReason | string? |
| ManagedBy | PaymentProvider |
| ExternalSubscriptionId | string? |

**`PromotionCampaign`**

| Property | Type |
|----------|------|
| Name | string |
| Description | string? |
| PromotionType | PromotionType |
| Value | decimal |
| MaxDiscountAmount | decimal? |
| CouponCode | string? |
| PartnerId | Guid? |
| PerUserUsageLimit | int |
| ApplicableProductTypesJson | string? |
| MinimumSpend | decimal |
| UsageLimit | int |
| UsageCount | int |
| StartsAt | DateTimeOffset |
| EndsAt | DateTimeOffset |
| IsActive | bool |

**`UserVoucher`** _(Payment — redemption record, khác IAM.UserVoucher)_

| Property | Type |
|----------|------|
| UserId | Guid |
| PromotionCampaignId | Guid |
| IsUsed | bool |
| UsedAt | DateTimeOffset? |
| UsedOnOrderId | Guid? |

**`PaymentWebhookEvent`**

| Property | Type |
|----------|------|
| Provider | string |
| EventType | string |
| ExternalEventId | string |
| PayloadJson | string? |
| Processed | bool |
| ProcessedAt | DateTimeOffset? |
| RetryCount | int |
| ErrorMessage | string? |

### Enums

| Enum | Values |
|------|--------|
| **TransactionStatus** | Pending=0, Processing=1, Succeeded=2, Failed=3, Refunded=4, Cancelled=5 |
| **TransactionType** | MealPurchase=0, SupplementPurchase=1, DigitalAssetPurchase=2, Subscription=3, WalletTopup=4, Refund=5, Reward=6 |
| **WalletTransactionType** | Credit=0, Debit=1, Reward=2, Purchase=3, Refund=4 |
| **SubscriptionStatus** | Trial=0, Active=1, PastDue=2, Cancelled=3, Expired=4, Paused=5 |
| **PromotionType** | PercentageDiscount=0, FixedDiscount=1, FreeDelivery=2, BonusCoins=3 |
| **PaymentMethod** | Wallet=0, Momo=1, COD=2, VietQR=3 |
| **PaymentProvider** | InternalWallet=1, GooglePlay=2, PayOS=3, Momo=4 |
| **PaymentMethodStatus** | Active=0, Expired=1, Revoked=2, PendingVerification=3 |
| **SpendingAuthorizationType** | ManualApproval=0, AiAutoApproved=1, ThresholdApproved=2, EmergencyBlocked=3 |

---

## Service: Order

> PostgreSQL (schema `order`) · `BaseAuditableEntity`  
> Redis: cart, delivery addresses, tracking cache (DTO, không phải domain entity)

### Entities

**`Order`**

| Property | Type |
|----------|------|
| UserId | Guid |
| PartnerId | Guid |
| OrderCode | string |
| Status | OrderStatus |
| SubtotalAmount | decimal |
| DeliveryFee | decimal |
| DiscountAmount | decimal |
| TotalAmount | decimal |
| Currency | string |
| PaymentTransactionId | Guid? |
| PaymentStatus | PaymentStatus |
| VoucherId | Guid? |
| VoucherCode | string? |
| DeliveryAddress | string? |
| DeliveryLat | decimal? |
| DeliveryLng | decimal? |
| RecipientName | string? |
| RecipientPhone | string? |
| Notes | string? |
| IsAiInitiated | bool |
| AIReasoningSnapshotJson | string? |
| PlacedAt | DateTimeOffset |
| ConfirmedAt | DateTimeOffset? |
| CompletedAt | DateTimeOffset? |
| CancelledAt | DateTimeOffset? |
| CancellationReason | string? |
| CancelledBy | CancelledByType? |
| Items | ICollection\<OrderItem\> |

**`OrderItem`**

| Property | Type |
|----------|------|
| OrderId | Guid |
| FoodMenuItemId | Guid |
| NameSnapshot | string |
| ImageUrlSnapshot | string? |
| UnitPrice | decimal |
| Quantity | int |
| Subtotal | decimal |
| Notes | string? |

**`DeliveryTracking`**

| Property | Type |
|----------|------|
| OrderId | Guid |
| Provider | string |
| ExternalDeliveryId | string? |
| ShipperName | string? |
| ShipperPhone | string? |
| ShipperPlateNumber | string? |
| Status | DeliveryStatus |
| LastKnownLat | decimal? |
| LastKnownLng | decimal? |
| LastLocationUpdatedAt | DateTimeOffset? |
| EstimatedArrivalAt | DateTimeOffset? |
| AssignedAt | DateTimeOffset? |
| PickedUpAt | DateTimeOffset? |
| DeliveredAt | DateTimeOffset? |

**`CommissionRecord`**

| Property | Type |
|----------|------|
| Source | CommissionSource |
| OrderId | Guid? |
| PartnerId | Guid |
| RelatedProductId | Guid? |
| ClickToken | string? |
| ExternalReferenceId | string? |
| GrossAmount | decimal |
| CommissionRate | decimal |
| CommissionAmount | decimal |
| Status | CommissionStatus |
| ConfirmedAt | DateTimeOffset? |
| PaidAt | DateTimeOffset? |

**`OrderStatusHistory`**

| Property | Type |
|----------|------|
| OrderId | Guid |
| FromStatus | OrderStatus? |
| ToStatus | OrderStatus |
| ChangedBy | string |
| Note | string? |

**`OrderIdempotencyKey`**

| Property | Type |
|----------|------|
| UserId | Guid |
| ClientRequestKey | string |
| OrderId | Guid |

**`DeliveryWebhookEvent`**

| Property | Type |
|----------|------|
| Provider | string |
| ExternalEventId | string |
| EventType | string |
| PayloadJson | string? |
| Processed | bool |
| ProcessedAt | DateTimeOffset? |
| ErrorMessage | string? |

### Enums

| Enum | Values |
|------|--------|
| **OrderStatus** | Pending=0, Confirmed=1, Preparing=2, ReadyForPickup=3, PickedUp=4, Delivering=5, Delivered=6, Completed=7, Cancelled=8, Refunded=9 |
| **PaymentStatus** | Unpaid=0, Paid=1, Refunded=2, Failed=3 |
| **DeliveryStatus** | Pending=0, Assigned=1, HeadingToPickup=2, ArrivedAtPickup=3, PickedUp=4, Delivering=5, Arrived=6, Completed=7, Failed=8, Cancelled=9 |
| **CommissionSource** | FoodDelivery=0, Affiliate=1 |
| **CommissionStatus** | Pending=0, Confirmed=1, Paid=2, Cancelled=3 |
| **CancelledByType** | User=0, Partner=1, System=2, Ahamove=3 |

---

## Service: Exercise

> MongoDB · `BaseMongoEntity`  
> Enums dùng từ **Libs.Shared**: `ExerciseCategory`, `Difficulty`, `MovementPattern`, `BodyRegion`, `AssetType`

### Entities

**`ExerciseCatalog`**

| Property | Type |
|----------|------|
| ExerciseCode | string |
| NameEn | string |
| NameVi | string |
| Slug | string |
| Category | ExerciseCategory |
| Difficulty | Difficulty |
| MovementPattern | MovementPattern |
| PrimaryMuscles | List\<string\> |
| SecondaryMuscles | List\<string\> |
| EquipmentRequired | List\<string\> |
| IsCompound | bool |
| ForceType | string |
| MechanicType | string |
| BodyRegion | BodyRegion |
| EstimatedCaloriesPerMinute | int |
| MetValue | decimal |
| RecommendedRestSeconds | int |
| Contraindications | List\<string\> |
| RecommendedGoals | List\<string\> |
| MovementTags | List\<string\> |
| AiCoachingCues | List\<string\> |
| CommonMistakes | List\<string\> |
| RequiresSpotter | bool |
| SafetyLevel | string |
| NeedsReview | bool |
| AiEnrichedAt | DateTimeOffset? |
| IsActive | bool |

**`ExerciseMotionAsset`**

| Property | Type |
|----------|------|
| ExerciseId | Guid |
| AssetType | AssetType |
| ResourceUrl | string |
| ThumbnailUrl | string? |
| S3Key | string? |
| ThumbnailS3Key | string? |
| UnityPrefabId | string? |
| UnityAnimationClip | string? |
| AnimationDurationSeconds | int |

**`WorkoutTemplate`**

| Property | Type |
|----------|------|
| Name | string |
| Goal | string |
| Difficulty | Difficulty |
| EstimatedDurationMinutes | int |
| TargetMuscleGroups | List\<string\> |
| RequiredEquipment | List\<string\> |
| EstimatedCaloriesBurn | int |
| AiRecoveryScore | int |
| IsSystemTemplate | bool |
| CreatedBy | string |
| Sessions | List\<TemplateSessionBlock\> |

**`WorkoutTemplate.TemplateSessionBlock`** _(nested)_

| Property | Type |
|----------|------|
| Order | int |
| ExerciseId | Guid |
| Sets | int |
| MinReps | int |
| MaxReps | int |
| RestSeconds | int |
| Tempo | string |
| Rir | int |
| Notes | string? |

---

## Service: Roadmap

> MongoDB · `BaseMongoEntity`  
> Enums dùng từ **Libs.Shared**: `RoadmapStatus`, `SessionStatus`, `Visibility`

### Entities

**`PersonalizedRoadmap`**

| Property | Type |
|----------|------|
| UserId | Guid |
| RoadmapName | string |
| FitnessGoal | string |
| CurrentPhase | string |
| StartDate | DateTimeOffset |
| ExpectedEndDate | DateTimeOffset? |
| CurrentWeightKg | decimal |
| TargetWeightKg | decimal |
| InitialFatPercentage | decimal |
| TargetFatPercentage | decimal |
| AdaptiveAiEnabled | bool |
| AllowAiReschedule | bool |
| AllowAiIntensityAdjustment | bool |
| AllowAiRecoveryDeload | bool |
| RoadmapStatus | RoadmapStatus |

**`RoadmapSession`**

| Property | Type |
|----------|------|
| RoadmapId | Guid |
| ScheduledDate | DateTimeOffset |
| ScheduledTime | string |
| Timezone | string |
| SessionType | string |
| SessionTitle | string |
| EstimatedDurationMinutes | int |
| EnergyDemandScore | int |
| RecoveryRequirementScore | int |
| NotificationEnabled | bool |
| NotificationMinutesBefore | int |
| AiGenerated | bool |
| SessionStatus | SessionStatus |
| ExecutionBlocks | List\<ExecutionBlock\> |

**`RoadmapSession.ExecutionBlock`** _(nested)_

| Property | Type |
|----------|------|
| Order | int |
| ExerciseId | Guid |
| ExerciseName | string |
| ExerciseAssetId | Guid? |
| TargetSets | int |
| TargetReps | int |
| TargetWeightKg | decimal |
| RestSeconds | int |
| Tempo | string |
| ExerciseNotes | string? |

**`ScheduledWorkout`**

| Property | Type |
|----------|------|
| UserId | Guid |
| SessionId | Guid |
| ScheduledStartTime | DateTimeOffset |
| ScheduledEndTime | DateTimeOffset |
| RepeatPattern | string |
| Status | SessionStatus |

**`UserCustomWorkout`**

| Property | Type |
|----------|------|
| UserId | Guid |
| WorkoutName | string |
| CoverRoadmapImageUrl | string? |
| Visibility | Visibility |
| ParentWorkoutId | Guid? |
| SavesCount | int |
| ScheduleMode | string |
| AllowAiOptimization | bool |
| CustomBlocks | List\<CustomBlock\> |

**`UserCustomWorkout.CustomBlock`** _(nested)_

| Property | Type |
|----------|------|
| ExerciseId | Guid |
| Sets | int |
| Reps | int |
| WeightKg | decimal |
| RestSeconds | int |

**`WorkoutExecutionLog`**

| Property | Type |
|----------|------|
| UserId | Guid |
| SessionId | Guid |
| StartedAt | DateTimeOffset |
| CompletedAt | DateTimeOffset? |
| ActualDurationMinutes | int |
| PerceivedDifficulty | int |
| EnergyLevelBefore | int |
| EnergyLevelAfter | int |
| CaloriesBurned | int |
| CompletionRate | int |
| AiCoachFeedback | string? |
| SkippedExercises | List\<Guid\> |
| SessionFeedback | string? |

**`ExerciseSetLog`**

| Property | Type |
|----------|------|
| ExecutionId | Guid |
| ExerciseId | Guid |
| SetNumber | int |
| TargetReps | int |
| ActualReps | int |
| WeightKg | decimal |
| Rir | int |
| RestTakenSeconds | int |
| FormScore | int |
| Completed | bool |

**`RecoveryProfile`**

| Property | Type |
|----------|------|
| UserId | Guid |
| CurrentRecoveryScore | int |
| FatigueLevel | int |
| MuscleSorenessScore | int |
| CnsFatigueScore | int |
| RecommendedTrainingIntensity | string |
| RecommendedWorkoutDuration | int |

---

## Service: Notification

> MongoDB · `BaseMongoEntity`

### Entities

**`NotificationMessage`**

| Property | Type |
|----------|------|
| UserId | Guid |
| Type | NotificationType |
| Channel | NotificationChannel |
| Priority | NotificationPriority |
| Title | string |
| Body | string |
| ImageUrl | string? |
| DeepLink | string? |
| DataPayloadJson | string? |
| AiContextSnapshotJson | string? |
| ScheduledFor | DateTimeOffset? |
| SentAt | DateTimeOffset? |
| DeliveredAt | DateTimeOffset? |
| ReadAt | DateTimeOffset? |
| Status | NotificationStatus |
| ErrorMessage | string? |

**`NotificationTemplate`**

| Property | Type |
|----------|------|
| TemplateCode | string |
| Name | string |
| DefaultTitle | string |
| DefaultBody | string |
| VariablesJson | string? |
| Channel | NotificationChannel |
| IsActive | bool |

### Enums

| Enum | Values |
|------|--------|
| **NotificationChannel** | Push=0, InApp=1, Email=2, Sms=3 |
| **NotificationStatus** | Pending=0, Sent=1, Delivered=2, Read=3, Failed=4, Cancelled=5 |
| **NotificationPriority** | Low=0, Normal=1, High=2, Urgent=3 |
| **NotificationType** | WorkoutReminder=0, MealAutoOrder=1, AiIntervention=2, Motivational=3, SystemAlert=4, RewardMinted=5, Promotion=6, PostLiked=7, PostCommented=8, CommentReplied=9, FollowAccepted=10, StoryViewed=11, StoryLiked=12, ChallengeCompleted=13, ChallengeRewardEarned=14, NewFollower=15, FollowRequested=16, NewPostFromFollowing=17 |

---

## Service: Social

> MongoDB · `BaseMongoEntity`

### Entities

**`CommunityChallenge`**

| Property | Type |
|----------|------|
| CreatorId | Guid |
| Title | string |
| Description | string |
| RegistrationDeadline | DateTimeOffset |
| StartDate | DateTimeOffset |
| EndDate | DateTimeOffset |
| GoalType | ChallengeGoalType? |
| PointRewards | decimal? |
| Gifts | string[]? |
| BackgroundUrl | string? |
| TargetValue | decimal? |
| ParticipantCount | int |
| Address | string? |
| Location | GeoJsonPoint\<GeoJson2DGeographicCoordinates\>? |
| Status | ChallengeStatus |

**`ChallengeParticipant`**

| Property | Type |
|----------|------|
| ChallengeId | Guid |
| UserId | Guid |
| Status | ParticipantStatus |
| JoinedAt | DateTimeOffset |
| CompletedAt | DateTimeOffset? |
| IsActive | bool |

**`Post`**

| Property | Type |
|----------|------|
| AuthorId | Guid |
| AuthorSnapshot | AuthorSnapshot |
| PostType | PostType |
| Content | string |
| MediaUrls | List\<string\> |
| ReferenceId | Guid? |
| Metrics | PostMetrics |
| IsPublic | bool |
| ShareCode | string |

**`Comment`**

| Property | Type |
|----------|------|
| PostId | Guid |
| UserId | Guid |
| Content | string |
| AuthorSnapshot | AuthorSnapshot? |
| ParentCommentId | Guid? |

**`Interaction`**

| Property | Type |
|----------|------|
| PostId | Guid |
| UserId | Guid |
| InteractionType | InteractionType |

**`Story`**

| Property | Type |
|----------|------|
| AuthorId | Guid |
| AuthorSnapshot | AuthorSnapshot |
| MediaUrl | string |
| MediaType | StoryMediaType |
| Caption | string? |
| ExpiresAt | DateTimeOffset |
| ViewCount | int |
| LikeCount | int |
| IsActive | bool |
| Privacy | PrivacyType |

**`StoryView`**

| Property | Type |
|----------|------|
| StoryId | Guid |
| ViewerId | Guid |
| ViewedAt | DateTimeOffset |

**`StoryInteraction`**

| Property | Type |
|----------|------|
| StoryId | Guid |
| UserId | Guid |
| InteractionType | InteractionType |

**`UserFollow`**

| Property | Type |
|----------|------|
| FollowerId | Guid |
| FolloweeId | Guid |
| FollowedAt | DateTimeOffset |
| Status | FollowStatus |

**`UserSocialSettings`**

| Property | Type |
|----------|------|
| UserId | Guid |
| ProfilePrivacy | PrivacyType |

**`Blog`**

| Property | Type |
|----------|------|
| AuthorId | Guid |
| AuthorSnapshot | AuthorSnapshot |
| Title | string |
| Slug | string |
| CoverImageUrl | string |
| MediaUrls | string[]? |
| Content | string |
| Tags | List\<string\> |
| Status | BlogStatus |
| PublishedAt | DateTimeOffset? |
| LikeCount | int |
| ShareCount | int |

**`BlogInteraction`**

| Property | Type |
|----------|------|
| BlogId | Guid |
| UserId | Guid |
| InteractionType | InteractionType |

### Nested types

**`AuthorSnapshot`** — denormalized author display data

| Property | Type |
|----------|------|
| FullName | string |
| AvatarUrl | string? |

**`PostMetrics`** — embedded counters trên Post

| Property | Type |
|----------|------|
| LikeCount | int |
| CommentCount | int |
| ShareCount | int |

### Enums

| Enum | Values |
|------|--------|
| **ChallengeGoalType** | TotalDistance=0, TotalWorkouts=1, TotalCaloriesBurned=2 |
| **ChallengeStatus** | Upcoming=0, Active=1, InProgress=2, Completed=3 |
| **ParticipantStatus** | Joined=0, InProgress=1, Completed=2, Dropped=3 |
| **PostType** | Standard=0, AchievementShare=1, StreakShare=2, ChallengeCreation=3 |
| **InteractionType** | Like=0, Share=1 |
| **FollowStatus** | Pending=0, Accepted=1, Blocked=2 |
| **PrivacyType** | Public=0, Followers=1, Private=2 |
| **StoryMediaType** | Image=0, Video=1, TextOnly=2 |
| **BlogStatus** | Draft=0, Published=1, Archived=2 |

---

## Service: Marketplace

> MongoDB · `BaseMongoEntity`  
> Enums dùng từ **Libs.Shared**: `FoodCategory`, `DietaryTag`

### Entities

**`Partner`**

| Property | Type |
|----------|------|
| OwnerUserId | Guid |
| Name | string |
| Slug | string |
| Type | PartnerType |
| Description | string? |
| LogoUrl | string? |
| CoverImageUrl | string? |
| Email | string |
| PhoneNumber | string? |
| Address | string? |
| Location | GeoJsonPoint\<GeoJson2DGeographicCoordinates\>? |
| ServiceRadiusKm | decimal? |
| OperatingHours | List\<OperatingHour\> |
| CommissionRate | decimal |
| Status | PartnerStatus |
| RatingAverage | decimal |
| RatingCount | int |
| IsAiRecommendable | bool |

**`Partner.OperatingHour`** _(nested)_

| Property | Type |
|----------|------|
| DayOfWeek | int |
| OpenTime | string |
| CloseTime | string |
| IsClosed | bool |

**`FoodMenuItem`**

| Property | Type |
|----------|------|
| PartnerId | Guid |
| NameVi | string |
| NameEn | string |
| Slug | string |
| Description | string |
| ImageUrls | List\<string\> |
| Category | FoodCategory |
| Price | decimal |
| Currency | string |
| PrepTimeMinutes | int |
| Nutrition | NutritionSnapshot |
| DietaryTags | List\<DietaryTag\> |
| SpiceLevel | SpiceLevel |
| Availability | AvailabilityStatus |
| IsAiRecommended | bool |
| RatingAverage | decimal |
| RatingCount | int |

**`AffiliateProduct`**

| Property | Type |
|----------|------|
| PartnerId | Guid? |
| BrandName | string |
| NameVi | string |
| NameEn | string |
| Slug | string |
| Description | string |
| ImageUrls | List\<string\> |
| Category | AffiliateCategory |
| Price | decimal |
| Currency | string |
| AffiliateUrl | string |
| ExternalProductId | string? |
| CommissionRate | decimal |
| Nutrition | NutritionSnapshot? |
| DietaryTags | List\<DietaryTag\>? |
| Availability | AvailabilityStatus |
| RatingAverage | decimal |
| RatingCount | int |

**`AffiliateClickEvent`**

| Property | Type |
|----------|------|
| UserId | Guid |
| AffiliateProductId | Guid |
| PartnerId | Guid? |
| ClickToken | string |
| Source | string |
| ClickedAt | DateTimeOffset |

**`Review`**

| Property | Type |
|----------|------|
| UserId | Guid |
| AuthorSnapshot | AuthorSnapshot |
| TargetType | ReviewTargetType |
| TargetId | Guid |
| Rating | int |
| Comment | string? |
| ImageUrls | List\<string\>? |
| OrderId | Guid? |
| IsVerifiedPurchase | bool |
| PartnerReply | string? |

### Nested types

**`AuthorSnapshot`** _(Marketplace)_

| Property | Type |
|----------|------|
| FullName | string |
| AvatarUrl | string? |

### Enums

| Enum | Values |
|------|--------|
| **PartnerType** | CloudKitchen=0, Restaurant=1, AffiliateBrand=2 |
| **PartnerStatus** | PendingApproval=0, Active=1, Suspended=2, Closed=3 |
| **AvailabilityStatus** | Available=0, SoldOut=1, Hidden=2 |
| **SpiceLevel** | None=0, Mild=1, Medium=2, Hot=3 |
| **AffiliateCategory** | Supplement=0, Equipment=1, Apparel=2, Accessory=3, Wearable=4, Other=5 |
| **ReviewTargetType** | Partner=0, FoodMenuItem=1, AffiliateProduct=2 |

---

## Service: Nutrition

> MongoDB · `BaseMongoEntity`  
> Enums dùng từ **Libs.Shared**: `MealType`, `FoodCategory`, `DietaryTag`

### Entities

**`FoodItem`**

| Property | Type |
|----------|------|
| NameVi | string |
| NameEn | string |
| Slug | string |
| Category | FoodCategory |
| Brand | string? |
| Barcode | string? |
| ServingSizeGram | decimal |
| ServingDescription | string? |
| CaloriesPer100g | int |
| ProteinPer100g | decimal |
| CarbPer100g | decimal |
| FatPer100g | decimal |
| FiberPer100g | decimal? |
| SugarPer100g | decimal? |
| SodiumMgPer100g | decimal? |
| DietaryTags | List\<DietaryTag\> |
| ImageUrl | string? |
| Source | FoodDataSource |
| MarketplaceItemId | Guid? |
| IsVerified | bool |
| IsActive | bool |

**`MealLog`**

| Property | Type |
|----------|------|
| UserId | Guid |
| MealType | MealType |
| LoggedAt | DateTimeOffset |
| Source | MealLogSource |
| Items | List\<MealLogItem\> |
| TotalCalories | int |
| TotalProteinGram | decimal |
| TotalCarbGram | decimal |
| TotalFatGram | decimal |
| PhotoUrl | string? |
| Notes | string? |
| RelatedOrderId | Guid? |

**`MealLog.MealLogItem`** _(nested)_

| Property | Type |
|----------|------|
| FoodItemId | Guid? |
| FoodNameSnapshot | string |
| QuantityGram | decimal |
| Calories | int |
| ProteinGram | decimal |
| CarbGram | decimal |
| FatGram | decimal |

**`DailyNutritionSummary`**

| Property | Type |
|----------|------|
| UserId | Guid |
| Date | DateOnly |
| TargetCalories | int |
| ConsumedCalories | int |
| TargetProteinGram | decimal |
| ConsumedProteinGram | decimal |
| TargetCarbGram | decimal |
| ConsumedCarbGram | decimal |
| TargetFatGram | decimal |
| ConsumedFatGram | decimal |
| WaterIntakeMl | int |
| MealsLoggedCount | int |

### Enums

| Enum | Values |
|------|--------|
| **FoodDataSource** | System=0, UserSubmitted=1, Marketplace=2, External=3 |
| **MealLogSource** | Manual=0, BarcodeScan=1, FromMarketplaceOrder=2, AiSuggested=3 |
| **MeasurementUnit** | Gram=0, Milliliter=1, Serving=2, Piece=3, Cup=4, Tablespoon=5, Bowl=6 |

---

## Service: Biometric

> Go service — không có C# domain layer.

---

## Thống kê

| Service | DB | Entities | Nested / Embedded | Enums |
|---------|-----|----------|-------------------|-------|
| Libs.Shared | — | 2 base + 1 VO | — | 11 |
| IAM | PostgreSQL | 10 | 1 (`AllergyItem`) | 12 |
| Payment | PostgreSQL | 8 | — | 9 |
| Order | PostgreSQL | 7 | — | 6 |
| Exercise | MongoDB | 3 | 1 | 0 (dùng Shared) |
| Roadmap | MongoDB | 7 | 2 | 0 (dùng Shared) |
| Notification | MongoDB | 2 | — | 4 |
| Social | MongoDB | 12 | 2 | 9 |
| Marketplace | MongoDB | 5 | 2 | 6 |
| Nutrition | MongoDB | 3 | 1 | 3 |
| **Total** | | **57 root entities** | **10** | **50** |

> **Lưu ý:** `UserVoucher` tồn tại ở cả **IAM** (inventory voucher) và **Payment** (redemption record) — hai entity khác nhau, database khác nhau.
