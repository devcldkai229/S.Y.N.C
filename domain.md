# Domain Model — Sync Lifestyle Automation Platform

> Trích xuất toàn bộ entities và enums từ tất cả services.  
> Storage: **PostgreSQL** (IAM, Payment) · **MongoDB** (Exercise, Roadmap, Notification, Social) · **Go** (Biometric)

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

**`BaseMongoEntity`** — dùng cho các service MongoDB (Exercise, Roadmap, Notification, Social)

| Property | Type |
|----------|------|
| Id | Guid |
| CreatedAt | DateTimeOffset |
| UpdatedAt | DateTimeOffset? |

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

---

## Service: IAM

> PostgreSQL · `BaseAuditableEntity`

### Entities

**`User`**

| Property | Type |
|----------|------|
| Email | string |
| PhoneNumber | string? |
| PasswordHash | string |
| FullName | string |
| AvatarUrl | string? |
| Role | UserRole |
| Status | UserStatus |
| SubscriptionTier | SubscriptionTier |
| EmailVerified | bool |
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
| StressScore | decimal |
| SleepQualityScore | decimal |
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

**`UserVoucher`**

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

**`AllergyItem`** _(record)_

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

> PostgreSQL · `BaseAuditableEntity`

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
| RelatedEntityType | string? |
| RelatedEntityId | Guid? |
| Description | string? |
| IsAiInitiated | bool |
| AIReasoningSnapshotJson | string? |
| SpendingAuthorizationType | SpendingAuthorizationType |
| ProcessedAt | DateTimeOffset? |
| FailedReason | string? |

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

**`PromotionCampaign`**

| Property | Type |
|----------|------|
| Name | string |
| PromotionType | PromotionType |
| Value | decimal |
| CouponCode | string? |
| ApplicableProductTypesJson | string? |
| MinimumSpend | decimal |
| UsageLimit | int |
| StartsAt | DateTimeOffset |
| EndsAt | DateTimeOffset |
| IsActive | bool |

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
| **PaymentMethod** | Wallet=0, Momo=1 |
| **PaymentMethodStatus** | Active=0, Expired=1, Revoked=2, PendingVerification=3 |
| **SpendingAuthorizationType** | ManualApproval=0, AiAutoApproved=1, ThresholdApproved=2, EmergencyBlocked=3 |

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
| ExerciseType | string |
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
| SafetyLevel | string |
| RequiresSpotter | bool |
| IsAiRecommended | bool |
| IsActive | bool |

**`ExerciseMotionAsset`**

| Property | Type |
|----------|------|
| ExerciseId | Guid |
| AssetType | AssetType |
| UnityPrefabId | string? |
| UnityAnimationClip | string? |
| VideoUrl | string? |
| ThumbnailUrl | string? |
| S3Key | string? |
| CdnUrl | string? |
| AnimationDurationSeconds | int |
| CameraAngles | List\<string\> |
| SupportsRealtimePoseOverlay | bool |
| PoseDetectionModel | string? |
| SupportsARMode | bool |
| SupportedPlatforms | List\<string\> |
| QualityVariants | List\<string\> |

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
| Visibility | Visibility |
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
| SleepRecoveryScore | int |
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

**`AuthorSnapshot`** — denormalized author display data (tránh join IAM khi load feed)

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

> Chưa có domain entities / enums.

---

## Service: Biometric

> Go service — không có C# domain layer.

---

## Thống kê

| Service | Entities | Nested types | Enums |
|---------|----------|--------------|-------|
| Libs.Shared | 2 base | — | 8 |
| IAM | 10 + 1 value object | — | 12 |
| Payment | 7 | — | 8 |
| Exercise | 3 | 1 | 0 (dùng Shared) |
| Roadmap | 7 | 2 | 0 (dùng Shared) |
| Notification | 2 | — | 4 |
| Social | 12 | 2 | 9 |
| **Total** | **43** | **5** | **41** |
