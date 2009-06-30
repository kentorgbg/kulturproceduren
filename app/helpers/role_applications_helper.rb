module RoleApplicationsHelper
  def state_string(application)
    case application.state
    when RoleApplication::PENDING then return "Inskickad"
    when RoleApplication::ACCEPTED then return "Godkänd"
    when RoleApplication::DENIED then return "Nekad"
    end
  end

  def type_string(application)
    case application.role.symbol_name
    when :booker then return "Bokning"
    when :host then return "Evenemangsvärd"
    when :culture_worker
      if application.culture_provider
        return "Publicering för #{h(application.culture_provider.name)}"
      else
        return "Publicering för #{h(application.new_culture_provider_name)}"
      end
    end
  end
end
