function cprintf(type, msg)
    if exist('cprintf', 'file')
        cprintf(type, msg);
    else
        fprintf(msg);
    end
end

