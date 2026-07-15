function code-word --description 'Generate a memorable adjective-noun project code word'
    if test (count $argv) -ne 0
        printf 'usage: code-word\n' >&2
        return 2
    end

    set -l adjectives \
        Agile Alert Amber Ancient Arctic Astral Autumnal Balanced Bashful Bold \
        Brave Breezy Bright Brisk Bronze Calm Careful Charming Cheerful Clever \
        Cloudy Cosmic Curious Daring Dawning Distant Dreamy Eager Electric Emerald \
        Epic Fabled Fearless Festive Fiery Fleet Focused Frosty Gentle Golden \
        Grand Happy Hidden Hopeful Icy Jolly Kind Lively Lucky Lunar \
        Magical Merry Misty Modern Mystic Nervous Nimble Noble Northern Oceanic \
        Peaceful Playful Polished Proud Quiet Quirky Rapid Ready Regal Relaxed \
        Restless Rustic Scarlet Serene Sharp Shining Silent Silver Sleepy Solar \
        Solid Spirited Steady Stoic Stormy Sunny Swift Tender Tidal Tranquil \
        Trusty Twilight Upbeat Verdant Vibrant Vigilant Wandering Warm Wild Wise \
        Witty Woodland Zealous

    set -l nouns \
        Albatross Alpaca Antelope Badger Bear Beaver Bison Bobcat Buffalo Bumblebee \
        Camel Canary Capybara Caribou Catfish Cheetah Chickadee Cobra Condor Cormorant \
        Cougar Coyote Crane Cricket Crow Dolphin Dormouse Dragonfly Eagle Egret \
        Falcon Ferret Finch Firefly Fox Gecko Gibbon Giraffe Goat Goose \
        Grouse Gull Hamster Hare Hawk Hedgehog Heron Ibex Iguana Jackal \
        Jaguar Jay Kestrel Kingfisher Kiwi Koala Lemur Leopard Lion Lizard \
        Llama Lobster Lynx Magpie Manatee Marmot Marten Meerkat Mink Moose \
        Narwhal Newt Ocelot Octopus Oriole Otter Owl Panda Panther Parrot \
        Peacock Pelican Penguin Pika Pony Porcupine Puffin Quail Rabbit Raccoon \
        Raven Robin Salmon Sandpiper Seal Sparrow Squid Starling Stork Swan \
        Tapir Tern Tiger Toucan Turkey Turtle Viper Walrus Weasel Whale \
        Wolf Wombat Wren Yak Zebra

    set -l adjective (random choice $adjectives)
    or return 1

    set -l noun (random choice $nouns)
    or return 1

    printf '%s %s\n' "$adjective" "$noun"
end
