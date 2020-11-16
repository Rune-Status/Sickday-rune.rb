module RuneRb::Game::Item
  class Click
    class << self
      include RuneRb::Types::Loggable

      def parse_action(type, assets)
        case type
        when :first_action then parse_first_action(assets[:context], assets[:frame])
        when :second_action then parse_second_action(assets[:context], assets[:frame])
        when :switch_item then parse_switch_item(assets[:context], assets[:frame])
        else
          err "Unrecognized action type: #{type}"
        end
      end


      def parse_option(type, assets)
        case type
        when :first_option then parse_first_option(assets[:context], assets[:frame])
        when :second_option then parse_second_option(assets[:context], assets[:frame])
        when :third_option then parse_third_option(assets[:context], assets[:frame])
        when :fourth_option then parse_fourth_option(assets[:context], assets[:frame])
        when :fifth_option then parse_fifth_option(assets[:context], assets[:frame])
        else
          err "Unrecognized option type: #{type}"
        end
      end

      # Parse a 1stItemOptionClick
      # @param context [RuneRb::Entity::Context] the context that clicked
      # @param frame [RuneRb::Network::InFrame] the incoming frame
      def parse_first_option(context, frame)
        interface = frame.read_short(false, :A, :LITTLE)
        slot = frame.read_short(false, :A)
        item_id = frame.read_short(false, :STD, :LITTLE)
        case interface
        when 3214
          log "Got Inventory Tab 1stOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        when 1688
          log "Got Equipment Tab 1stOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err"Unhandled 1stOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

      # Parse a 2ndItemOptionClick
      # @param context [RuneRb::Entity::Context]
      # @param frame [RuneRb::Network::InFrame]
      def parse_second_option(context, frame)
        item_id = frame.read_short(false)
        slot = frame.read_short(false, :A) + 1
        interface = frame.read_short(false, :A)
        case interface
        when 3214
          item = context.inventory.at(slot)
          return unless item # This check is for instances where a context may perform a 5thoptclick followed by this 2ndoptclick. this slot may be nil, so we do nothing and sort of force a proper click.

          old = context.equipment[item.definition[:slot]]
          context.equipment[item.definition[:slot]] = item
          context.inventory.remove_at(slot)
          context.inventory.add(old, slot) if old.is_a?(RuneRb::Game::Item::Stack)
          context.update(:equipment)
          context.update(:inventory)
          log "Got Inventory Tab 2ndOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface} || [old]: #{old.is_a?(Integer) ? old : old.id}"
        when 1688
          log "Got Equipment Tab 2ndOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err"Unhandled 2ndOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

      # Parse a 3rdItemOptionClick
      # @param context [RuneRb::Entity::Context]
      # @param frame [RuneRb::Network::InFrame]
      def parse_third_option(context, frame)
        item_id = frame.read_short(false, :A)
        slot = frame.read_short(false, :A, :LITTLE)
        interface = frame.read_short(false, :A, :LITTLE)
        case interface
        when 3214
          log "Got Inventory Tab 3rdOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        when 1688
          log "Got Equipment Tab 3rdOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err"Unhandled 3rdOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

      # Parse a 4thItemOptionClick
      # @param context [RuneRb::Entity::Context]
      # @param frame [RuneRb::Network::InFrame]
      def parse_fourth_option(context, frame)
        interface = frame.read_short(false, :A, :LITTLE)
        slot = frame.read_short(false, :STD, :LITTLE)
        item_id = frame.read_short(false, :A)
        case interface
        when 3214
          log "Got Inventory Tab 4thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        when 1688
          log "Got Equipment Tab 4thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err"Unhandled 4thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

      # Parse a 5thItemOptionClick
      # @param context [RuneRb::Entity::Context]
      # @param frame [RuneRb::Network::InFrame]
      def parse_fifth_option(context, frame)
        item_id = frame.read_short(false, :A)
        interface = frame.read_short(false)
        slot = frame.read_short(false, :A) + 1
        case interface
        when 3214
          return unless context.inventory.has?(item_id, slot)

          ## TODO: Implement and call create ground item
          context.inventory.remove_at(slot)
          context.update(:inventory)
          log "Got Inventory 5thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        when 1688
          log "Got Equipment 5thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err "Unrecognized 5thOptionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

      def parse_switch_item(context, frame)
        interface = frame.read_short(false, :A, :LITTLE)
        inserting = frame.read_byte(false, :C) # This will matter when bank is implemented. TODO: impl bank
        old_slot = frame.read_short(false, :A, :LITTLE)
        new_slot = frame.read_short(false, :STD, :LITTLE)
        case interface
        when 3214
          if old_slot >= 0 &&
              new_slot >= 0 &&
              old_slot <= context.inventory.capacity &&
              new_slot <= context.inventory.capacity
            context.inventory.swap(old_slot, new_slot)
            context.update(:inventory)
          end
          log "Got Inventory SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{inserting} || [interface]: #{interface}"
        when 1688
          log "Got Equipment SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{inserting} || [interface]: #{interface}"
        else
          err "Unrecognized SwitchItemClick: [old_slot]: #{old_slot} || [new_slot]: #{new_slot} || [inserting]: #{inserting} || [interface]: #{interface}"
        end
      end

      def parse_first_action(context, frame)
        interface = frame.read_short(false, :A)
        slot = frame.read_short(false, :A)
        item_id = frame.read_short(false, :A)
        case interface
        when 3214 # Inventory = EquipItem or Eat food, or break a teletab (not really)
          log "Got Inventory Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        when 1688 # EquipmentTab
          if context.inventory.add(RuneRb::Game::Item::Stack.new(item_id))
            context.equipment.unequip(slot)
            context.update(:equipment)
            context.update(:inventory)
          else
            context.session.write_text("You don't have enough space in your inventory to do this.")
          end
          log "Got Equipment Tab 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err "Unrecognized 1stActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

      def parse_second_action(context, frame)
        item_id = frame.read_short(false)
        slot = frame.read_short(false, :A)  + 1 # This is the Slot that was clicked.
        interface = frame.read_short(false, :A)
        case interface
        when 3214 # Inventory Tab
          log "Got Inventory Tab 2ndActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        when 1688 # Equipment Tab
          log "Got Equipment Tab 2ndActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        else
          err "Unrecognized 2ndActionClick: [slot]: #{slot} || [item]: #{item_id} || [interface]: #{interface}"
        end
      end

    end
  end
end