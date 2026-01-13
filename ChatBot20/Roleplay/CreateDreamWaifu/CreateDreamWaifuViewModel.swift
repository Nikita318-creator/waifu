import UIKit

class CreateDreamWaifuViewModel {
    var slides: [WaifuSlideData] {
        return [
            WaifuSlideData(
                title: "CreateDreamWaifu.slide1.title".localize(),
                marketingText: "CreateDreamWaifu.slide1.marketing".localize(),
                imageName: "CreateDreamWaifu1",
                questions: [
                    WaifuQuestion(
                        id: "hair_style",
                        title: "CreateDreamWaifu.question.hair_style.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.short".localize(),
                            "CreateDreamWaifu.option.long".localize(),
                            "CreateDreamWaifu.option.ponytails".localize(),
                            "CreateDreamWaifu.option.neon".localize(),
                            "CreateDreamWaifu.option.pastel".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "eye_type",
                        title: "CreateDreamWaifu.question.eye_type.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.almond".localize(),
                            "CreateDreamWaifu.option.big_doe".localize(),
                            "CreateDreamWaifu.option.glowing_red".localize(),
                            "CreateDreamWaifu.option.mysterious_purple".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "body_face",
                        title: "CreateDreamWaifu.question.body_face.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.cute".localize(),
                            "CreateDreamWaifu.option.mature".localize(),
                            "CreateDreamWaifu.option.petite".localize(),
                            "CreateDreamWaifu.option.curvy".localize(),
                            "CreateDreamWaifu.option.pale".localize(),
                            "CreateDreamWaifu.option.tanned".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "fetish_traits",
                        title: "CreateDreamWaifu.question.fetish_traits.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.cat_ears".localize(),
                            "CreateDreamWaifu.option.tail".localize(),
                            "CreateDreamWaifu.option.glasses".localize(),
                            "CreateDreamWaifu.option.collar".localize(),
                            "CreateDreamWaifu.option.ribbons".localize()
                        ],
                        allowMultipleSelection: true
                    )
                ]
            ),
            WaifuSlideData(
                title: "CreateDreamWaifu.slide2.title".localize(),
                marketingText: "CreateDreamWaifu.slide2.marketing".localize(),
                imageName: "CreateDreamWaifu2",
                questions: [
                    WaifuQuestion(
                        id: "main_style",
                        title: "CreateDreamWaifu.question.main_style.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.school_uniform".localize(),
                            "CreateDreamWaifu.option.maid_outfit".localize(),
                            "CreateDreamWaifu.option.fantasy_armor".localize(),
                            "CreateDreamWaifu.option.casual_chic".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "accessories",
                        title: "CreateDreamWaifu.question.accessories.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.stockings".localize(),
                            "CreateDreamWaifu.option.gloves".localize(),
                            "CreateDreamWaifu.option.jewelry".localize(),
                            "CreateDreamWaifu.option.chokers".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "seasonal",
                        title: "CreateDreamWaifu.question.seasonal.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.summer_bikini".localize(),
                            "CreateDreamWaifu.option.winter_sweater".localize(),
                            "CreateDreamWaifu.option.cosplay".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "underwear",
                        title: "CreateDreamWaifu.question.underwear.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.cute".localize(),
                            "CreateDreamWaifu.option.lacy".localize(),
                            "CreateDreamWaifu.option.provocative".localize(),
                            "CreateDreamWaifu.option.none".localize()
                        ],
                        allowMultipleSelection: false
                    )
                ]
            ),
            WaifuSlideData(
                title: "CreateDreamWaifu.slide3.title".localize(),
                marketingText: "CreateDreamWaifu.slide3.marketing".localize(),
                imageName: "CreateDreamWaifu3",
                questions: [
                    WaifuQuestion(
                        id: "archetype",
                        title: "CreateDreamWaifu.question.archetype.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.tsundere".localize(),
                            "CreateDreamWaifu.option.yandere".localize(),
                            "CreateDreamWaifu.option.kuudere".localize(),
                            "CreateDreamWaifu.option.deredere".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "speech_style",
                        title: "CreateDreamWaifu.question.speech_style.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.flirty".localize(),
                            "CreateDreamWaifu.option.teasing".localize(),
                            "CreateDreamWaifu.option.shy".localize(),
                            "CreateDreamWaifu.option.oniichan".localize(),
                            "CreateDreamWaifu.option.mature".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "reactions",
                        title: "CreateDreamWaifu.question.reactions.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.jealousy".localize(),
                            "CreateDreamWaifu.option.supportive".localize(),
                            "CreateDreamWaifu.option.playful_pranks".localize(),
                            "CreateDreamWaifu.option.protective".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "hidden_depth",
                        title: "CreateDreamWaifu.question.hidden_depth.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.gamer".localize(),
                            "CreateDreamWaifu.option.cook".localize(),
                            "CreateDreamWaifu.option.clingy".localize(),
                            "CreateDreamWaifu.option.perfectionist".localize(),
                            "CreateDreamWaifu.option.artist".localize()
                        ],
                        allowMultipleSelection: true
                    )
                ]
            ),
            WaifuSlideData(
                title: "CreateDreamWaifu.slide4.title".localize(),
                marketingText: "CreateDreamWaifu.slide4.marketing".localize(),
                imageName: "CreateDreamWaifu4",
                questions: [
                    WaifuQuestion(
                        id: "origin",
                        title: "CreateDreamWaifu.question.origin.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.fantasy_kingdom".localize(),
                            "CreateDreamWaifu.option.modern_tokyo".localize(),
                            "CreateDreamWaifu.option.alien_planet".localize(),
                            "CreateDreamWaifu.option.virtual_world".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "goal",
                        title: "CreateDreamWaifu.question.goal.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.adventure".localize(),
                            "CreateDreamWaifu.option.protect_you".localize(),
                            "CreateDreamWaifu.option.build_family".localize(),
                            "CreateDreamWaifu.option.discover_herself".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "drama",
                        title: "CreateDreamWaifu.question.drama.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.rivals".localize(),
                            "CreateDreamWaifu.option.enemies".localize(),
                            "CreateDreamWaifu.option.forbidden_secret".localize(),
                            "CreateDreamWaifu.option.past_trauma".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "connection",
                        title: "CreateDreamWaifu.question.connection.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.love_at_first_sight".localize(),
                            "CreateDreamWaifu.option.childhood_friend".localize(),
                            "CreateDreamWaifu.option.soulmate".localize(),
                            "CreateDreamWaifu.option.arranged_meeting".localize()
                        ],
                        allowMultipleSelection: false
                    )
                ]
            ),
            WaifuSlideData(
                title: "CreateDreamWaifu.slide5.title".localize(),
                marketingText: "CreateDreamWaifu.slide5.marketing".localize(),
                imageName: "CreateDreamWaifu4_1",
                questions: [
                    WaifuQuestion(
                        id: "affection",
                        title: "CreateDreamWaifu.question.affection.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.hugs".localize(),
                            "CreateDreamWaifu.option.passionate_kisses".localize(),
                            "CreateDreamWaifu.option.dominant_whispers".localize(),
                            "CreateDreamWaifu.option.soft_touches".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "scenario",
                        title: "CreateDreamWaifu.question.scenario.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.date_night".localize(),
                            "CreateDreamWaifu.option.battle_side_by_side".localize(),
                            "CreateDreamWaifu.option.bedtime".localize(),
                            "CreateDreamWaifu.option.morning_routine".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    WaifuQuestion(
                        id: "secret",
                        title: "CreateDreamWaifu.question.secret.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.hidden_desires".localize(),
                            "CreateDreamWaifu.option.custom_voice".localize(),
                            "CreateDreamWaifu.option.secret_power".localize(),
                            "CreateDreamWaifu.option.vulnerability".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    WaifuQuestion(
                        id: "evolution",
                        title: "CreateDreamWaifu.question.evolution.title".localize(),
                        options: [
                            "CreateDreamWaifu.option.level_loyalty".localize(),
                            "CreateDreamWaifu.option.unlock_outfits".localize(),
                            "CreateDreamWaifu.option.personality_shifts".localize(),
                            "CreateDreamWaifu.option.all_above".localize()
                        ],
                        allowMultipleSelection: false
                    )
                ]
            )
        ]
    }
}
