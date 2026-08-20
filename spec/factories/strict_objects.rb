# frozen_string_literal: true

FactoryBot.define do
  factory :accessor, class: "AccessorClass" do
    skip_create

    foo { 1 }
    bar { "2" }
    baz { "3" }

    initialize_with { new(**attributes) }
  end

  factory :strict_object, class: "ObjectClass" do
    skip_create

    foo { 1 }
    bar { "2" }
    baz { "3" }

    initialize_with { new(**attributes) }
  end

  factory :reader, class: "ReaderClass" do
    skip_create

    foo { 1 }
    bar { "2" }
    baz { "3" }

    initialize_with { new(**attributes) }
  end

  factory :value, class: "ValueClass" do
    skip_create

    foo { 1 }
    bar { "2" }
    baz { "3" }

    initialize_with { new(**attributes) }
  end

  factory :other_value, class: "OtherValueClass" do
    skip_create

    foo { 1 }
    bar { "2" }
    baz { "3" }

    initialize_with { new(**attributes) }
  end
end
